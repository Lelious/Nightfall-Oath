using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using System.Linq;

public class MeshBuilder : EditorWindow
{
    private float fixedStep = 3f;
    private float thresholdY = 10f;
    private int rings = 3;
    private List<Vector3> points = new List<Vector3>();
    private GameObject previewObject;
    private Mesh currentMesh;
    private Material targetMaterial;
    private bool isEditing = false;

    [MenuItem("Tools/NavMesh Builder")]
    public static void ShowWindow() => GetWindow<MeshBuilder>("NavMesh Builder");

    private void OnEnable()
    {
        SceneView.duringSceneGui += OnSceneGUI;

        if (targetMaterial == null)
        {
            targetMaterial = AssetDatabase.LoadAssetAtPath<Material>("Assets/Materials/Build/Build.mat");
        }
    }

    private void OnDisable() => SceneView.duringSceneGui -= OnSceneGUI;

    private void OnSceneGUI(SceneView sceneView)
    {
        if (!HasOpenInstances<MeshBuilder>())
            return;

        if (!isEditing) return;

        int controlID = GUIUtility.GetControlID(FocusType.Passive);
        HandleUtility.AddDefaultControl(controlID);

        Event e = Event.current;

        if (e.type == EventType.KeyDown && e.control && e.keyCode == KeyCode.Z)
        {
            RemoveLastPoint();
            e.Use();
        }

        if (e.type == EventType.MouseDown && e.button == 0 && e.shift)
        {
            Ray ray = HandleUtility.GUIPointToWorldRay(e.mousePosition);
            if (Physics.Raycast(ray, out RaycastHit hit))
            {
                Vector3 newPoint = hit.point + Vector3.up * 0.05f;
                if (points.Count == 0 || Vector3.Distance(points[points.Count - 1], newPoint) > 0.5f)
                {
                    points.Add(newPoint);
                    EditorUtility.SetDirty(this);
                }
                e.Use();
            }
        }

        Handles.color = Color.green;
        int totalPoints = points.Count;

        for (int i = 0; i < points.Count;  i++)
        {
            if(i > 0)
            {
                Handles.DrawLine(points[i - 1], points[i]);
            }
        }

        if (totalPoints > 2)
        {
            Handles.color = Color.yellow;
            Handles.DrawLine(points[totalPoints - 1], points[0]);
        }

        if (e.type == EventType.MouseMove)
        {
            sceneView.Repaint();
        }
    }

    private void RemoveLastPoint()
    {
        if (points.Count > 0)
        {
            points.RemoveAt(points.Count - 1);
            SceneView.RepaintAll();
        }
    }

    private void OnGUI()
    {
        GUI.color = isEditing ? Color.green : Color.gray;
        if (GUILayout.Button(isEditing ? "Is Editing Mode : YES" : "Is Editing Mode : NO", GUILayout.Height(30)))
        {
            isEditing = !isEditing;
        }
        GUI.color = Color.white;

        GUILayout.Label("Grid settings", EditorStyles.boldLabel);
        fixedStep = EditorGUILayout.Slider("Grid Step", fixedStep, 0.5f, 10f);
        rings = EditorGUILayout.IntSlider("Rings Count (Radial)", rings, 1, 10);
        thresholdY = EditorGUILayout.Slider("Raycast Y Threshold", thresholdY, 0.1f, 100f);
        targetMaterial = (Material)EditorGUILayout.ObjectField("Material", targetMaterial, typeof(Material), false);

        EditorGUILayout.Space();

        if (currentMesh != null)
        {
            EditorGUILayout.LabelField("Vertices :", currentMesh.vertexCount.ToString());
            EditorGUILayout.LabelField("Triangles :", (currentMesh.triangles.Length / 3).ToString());
        }

        EditorGUILayout.Space();

        GUILayout.Label("Input:", EditorStyles.helpBox);
        GUILayout.Label("• Shift + LftMouse : Add point\n• Ctrl + Z : Undo");

        GUI.color = Color.green;
        if (GUILayout.Button("Generate Mesh (Grid)", GUILayout.Height(30))) GenerateMesh();

        GUI.color = Color.green;
        if (GUILayout.Button("Generate Mesh (Radial)", GUILayout.Height(30))) GenerateRadialMesh();

        GUI.color = Color.yellow;
        if (GUILayout.Button("Delete Mesh", GUILayout.Height(30))) DeleteGeneratedMesh();
        GUI.color = Color.white;

        GUI.color = Color.red;
        if (GUILayout.Button("Clear All", GUILayout.Height(30))) points.Clear();
        GUI.color = Color.white;

        GUI.enabled = (currentMesh != null);
        if (GUILayout.Button("Save as Asset", GUILayout.Height(30))) SaveMesh();
        GUI.enabled = true;
    }

    private void GenerateMesh()
    {
        if (points.Count < 3) return;

        List<Vector3> combinedPoints = new List<Vector3>();

        for (int i = 0; i < points.Count; i++)
        {
            Vector3 start = points[i];
            Vector3 end = points[(i + 1) % points.Count];
            float dist = Vector3.Distance(start, end);
            int divisions = Mathf.Max(1, Mathf.RoundToInt(dist / fixedStep));
            for (int d = 0; d < divisions; d++)
            {
                combinedPoints.Add(Vector3.Lerp(start, end, (float)d / divisions));
            }
        }

        Bounds b = new Bounds(points[0], Vector3.zero);
        foreach (var p in points) b.Encapsulate(p);

        List<Vector2> poly2D = points.Select(p => new Vector2(p.x, p.z)).ToList();
        float safetyMargin = fixedStep * 0.5f;

        for (float x = b.min.x + fixedStep; x < b.max.x; x += fixedStep)
        {
            for (float z = b.min.z + fixedStep; z < b.max.z; z += fixedStep)
            {
                Vector2 p2d = new Vector2(x, z);

                if (IsPointInPolygon(poly2D, p2d) && GetDistanceToPoly(p2d, poly2D) > safetyMargin)
                {
                    combinedPoints.Add(new Vector3(x, b.center.y, z));
                }
            }
        }

        Vector3[] finalVerts = new Vector3[combinedPoints.Count];
        for (int i = 0; i < combinedPoints.Count; i++)
        {
            Vector3 pos = combinedPoints[i];
            if (Physics.Raycast(pos + Vector3.up * thresholdY, Vector3.down, out RaycastHit hit))
                pos = hit.point;
            finalVerts[i] = pos + Vector3.up * 0.01f;
        }

        GenerateGridMeshWithSnapping(poly2D, b);
    }

    private void GenerateGridMeshWithSnapping(List<Vector2> poly, Bounds b)
    {
        List<Vector3> verts = new List<Vector3>();
        List<int> tris = new List<int>();

        int xCount = Mathf.CeilToInt(b.size.x / fixedStep) + 2;
        int zCount = Mathf.CeilToInt(b.size.z / fixedStep) + 2;
        int[,] nodes = new int[xCount, zCount];

        for (int ix = 0; ix < xCount; ix++)
        {
            for (int iz = 0; iz < zCount; iz++)
            {
                nodes[ix, iz] = -1;
                Vector2 p2d = new Vector2(b.min.x + (ix - 0.5f) * fixedStep, b.min.z + (iz - 0.5f) * fixedStep);

                Vector2 finalP2D;
                bool isInside = IsPointInPolygon(poly, p2d);

                if (isInside)
                {
                    finalP2D = SnapToPolygon(p2d, poly, fixedStep * 0.5f);
                }
                else
                {
                    finalP2D = SnapToPolygon(p2d, poly, fixedStep * 1.5f);

                    if (Vector2.Distance(p2d, finalP2D) > fixedStep * 1.2f) continue;
                }

                Vector3 worldPos = new Vector3(finalP2D.x, b.center.y, finalP2D.y);
                if (Physics.Raycast(worldPos + Vector3.up * thresholdY, Vector3.down, out RaycastHit hit))
                    worldPos = hit.point;

                verts.Add(worldPos + Vector3.up * 0.02f);
                nodes[ix, iz] = verts.Count - 1;
            }
        }

        for (int ix = 0; ix < xCount - 1; ix++)
        {
            for (int iz = 0; iz < zCount - 1; iz++)
            {
                int a = nodes[ix, iz];
                int bN = nodes[ix + 1, iz];
                int c = nodes[ix, iz + 1];
                int d = nodes[ix + 1, iz + 1];

                if (a != -1 && bN != -1 && c != -1)
                {
                    if (IsAnyPointInOrOnPoly(poly, a, bN, c, verts))
                    {
                        tris.Add(a); tris.Add(c); tris.Add(bN);
                    }
                }
                if (bN != -1 && d != -1 && c != -1)
                {
                    if (IsAnyPointInOrOnPoly(poly, bN, d, c, verts))
                    {
                        tris.Add(bN); tris.Add(c); tris.Add(d);
                    }
                }
            }
        }
        ApplyToMesh(verts, tris);
    }

    private Vector2 SnapToPolygon(Vector2 p, List<Vector2> poly, float maxSnapDist)
    {
        Vector2 closest = p;
        float minDist = maxSnapDist;

        for (int i = 0; i < poly.Count; i++)
        {
            Vector2 a = poly[i];
            Vector2 b = poly[(i + 1) % poly.Count];
            Vector2 projection = ProjectPointOnLineSegment(p, a, b);
            float d = Vector2.Distance(p, projection);
            if (d < minDist)
            {
                minDist = d;
                closest = projection;
            }
        }
        return closest;
    }

    private Vector2 ProjectPointOnLineSegment(Vector2 p, Vector2 a, Vector2 b)
    {
        Vector2 r = b - a;
        float l2 = r.sqrMagnitude;
        if (l2 == 0) return a;
        float t = Mathf.Clamp01(Vector2.Dot(p - a, r) / l2);
        return a + t * r;
    }

    private float GetDistanceToPoly(Vector2 p, List<Vector2> poly)
    {
        float minDist = float.MaxValue;
        for (int i = 0; i < poly.Count; i++)
        {
            float d = Vector2.Distance(p, ProjectPointOnLineSegment(p, poly[i], poly[(i + 1) % poly.Count]));
            if (d < minDist) minDist = d;
        }
        return minDist;
    }
    
    private bool IsAnyPointInOrOnPoly(List<Vector2> poly, int i1, int i2, int i3, List<Vector3> v)
    {
        Vector2 p1 = new Vector2(v[i1].x, v[i1].z);
        Vector2 p2 = new Vector2(v[i2].x, v[i2].z);
        Vector2 p3 = new Vector2(v[i3].x, v[i3].z);

        Vector2 center = (p1 + p2 + p3) / 3f;
        return IsPointInPolygon(poly, center);
    }

    private void ApplyToMesh(List<Vector3> verts, List<int> tris)
    {
        if (currentMesh == null) currentMesh = new Mesh();
        currentMesh.Clear();
        currentMesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
        currentMesh.vertices = verts.ToArray();
        currentMesh.triangles = tris.ToArray();
        currentMesh.RecalculateNormals();

        if (currentMesh.normals.Length > 0 && currentMesh.normals[0].y < 0)
        {
            for (int i = 0; i < tris.Count; i += 3)
            {
                int temp = tris[i];
                tris[i] = tris[i + 1];
                tris[i + 1] = temp;
            }
            currentMesh.triangles = tris.ToArray();
            currentMesh.RecalculateNormals();
        }
        UpdatePreview();
    }

    private bool IsPointInPolygon(List<Vector2> poly, Vector2 p)
    {
        bool inside = false;
        for (int i = 0, j = poly.Count - 1; i < poly.Count; j = i++)
        {
            if (((poly[i].y > p.y) != (poly[j].y > p.y)) &&
                (p.x < (poly[j].x - poly[i].x) * (p.y - poly[i].y) / (poly[j].y - poly[i].y) + poly[i].x))
                inside = !inside;
        }
        return inside;
    }

    private void GenerateRadialMesh()
    {
        if (points.Count < 3) return;

        List<Vector3> contour = new List<Vector3>();
        for (int i = 0; i < points.Count; i++)
        {
            Vector3 start = points[i];
            Vector3 end = points[(i + 1) % points.Count];
            float dist = Vector3.Distance(start, end);
            int divisions = Mathf.Max(1, Mathf.RoundToInt(dist / fixedStep));

            for (int d = 0; d < divisions; d++)
            {
                contour.Add(Vector3.Lerp(start, end, (float)d / divisions));
            }
        }

        Vector3 center = Vector3.zero;
        foreach (var p in contour) center += p;
        center /= contour.Count;

        if (Physics.Raycast(center + Vector3.up * thresholdY, Vector3.down, out RaycastHit hitCenter))
            center = hitCenter.point;

        List<Vector3> verts = new List<Vector3>();
        List<int> tris = new List<int>();

        int ptsCount = contour.Count;
        for (int r = 0; r <= rings; r++)
        {
            float t = (float)r / rings;
            for (int i = 0; i < ptsCount; i++)
            {
                Vector3 pos = Vector3.Lerp(contour[i], center, t);

                if (Physics.Raycast(pos + Vector3.up * thresholdY, Vector3.down, out RaycastHit hit))
                    pos = hit.point;

                verts.Add(pos + Vector3.up * 0.02f);
            }
        }

        for (int r = 0; r < rings; r++)
        {
            for (int i = 0; i < ptsCount; i++)
            {
                int next = (i + 1) % ptsCount;

                int vIdx = r * ptsCount + i;
                int vNext = r * ptsCount + next;
                int vInner = (r + 1) * ptsCount + i;
                int vInnerNext = (r + 1) * ptsCount + next;

                tris.Add(vIdx);
                tris.Add(vNext);
                tris.Add(vInner);

                tris.Add(vInner);
                tris.Add(vNext);
                tris.Add(vInnerNext);
            }
        }

        UpdateMeshAsset(verts, tris);
    }

    private void UpdateMeshAsset(List<Vector3> verts, List<int> tris)
    {
        if (currentMesh == null) currentMesh = new Mesh();
        currentMesh.Clear();
        currentMesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
        currentMesh.vertices = verts.ToArray();
        currentMesh.triangles = tris.ToArray();
        currentMesh.RecalculateNormals();

        if (currentMesh.normals.Length > 0 && currentMesh.normals[0].y < 0)
        {
            for (int i = 0; i < tris.Count; i += 3)
            {
                int tmp = tris[i]; tris[i] = tris[i + 1]; tris[i + 1] = tmp;
            }
            currentMesh.triangles = tris.ToArray();
            currentMesh.RecalculateNormals();
        }

        UpdatePreview();
    }

    private void UpdatePreview()
    {
        if (previewObject == null)
        {
            previewObject = new GameObject("NavMesh_Preview");
            previewObject.AddComponent<MeshFilter>();
            previewObject.AddComponent<MeshRenderer>();
        }
        previewObject.GetComponent<MeshFilter>().sharedMesh = currentMesh;
        previewObject.GetComponent<MeshRenderer>().sharedMaterial = targetMaterial;
        previewObject.layer = LayerMask.NameToLayer("WalkGround");
        Selection.activeGameObject = previewObject;
    }

    private void DeleteGeneratedMesh()
    {
        if(previewObject != null)
        {
            DestroyImmediate(previewObject);
        }

        currentMesh = null;
    }

    private void SaveMesh()
    {
        if (currentMesh == null) return;

        string folderPath = "Assets/GeneratedMeshes";
        if (!AssetDatabase.IsValidFolder(folderPath)) AssetDatabase.CreateFolder("Assets", "GeneratedMeshes");

        string path = EditorUtility.SaveFilePanelInProject("Save Mesh", "NavMesh_Asset", "asset", "Type Asset Name", folderPath);

        if (!string.IsNullOrEmpty(path))
        {
            Mesh meshToSave = Instantiate(currentMesh);
            meshToSave.Optimize();
            AssetDatabase.CreateAsset(meshToSave, path);
            AssetDatabase.SaveAssets();

            if (previewObject != null)
            {
                previewObject.GetComponent<MeshFilter>().sharedMesh = AssetDatabase.LoadAssetAtPath<Mesh>(path);
                previewObject.name = System.IO.Path.GetFileNameWithoutExtension(path);
                previewObject = null;
                currentMesh = null;
            }

            Debug.Log($"<color=green>Mesh saved sucessfully: {path}</color>");
        }
    }
}
