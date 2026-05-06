using LeliousExtentions;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Unity.AI.Navigation;
using UnityEditor;
using UnityEngine;

[ExecuteInEditMode]
public class MeshCopier : MonoBehaviour
{
    [SerializeField] private Terrain _terrain;    
    [SerializeField] private Texture2D _heightMap;
    [SerializeField] private Vector3 _startPos;
    [SerializeField] private Vector3 _startPosVertex;
    [SerializeField] private NavMeshSurface _navSurf;
    [SerializeField] private GameObject _navQuad;
    [SerializeField] private Vector2Int _buildQuadSize;
    [SerializeField] private List<GameObject> _chunks;

    public float minHeight, maxHeight;
    public int chunkX;
    public int chunkY;
    public int tileResolution = 64;
    public int chunksPerSide = 20;
    public float chunkSize = 100f;

    [SerializeField] private int highestX, highestZ = 0;
    private const float _distPervertex = 1.5873f;
    private string _savePathSplat = "Assets/Chunks/Splatmaps/";
    private string _saveHeightPath = "Assets/Chunks/HeightMap/";
    private string _saveChunkDataPath = "Assets/Chunks/ChunkData/";


    private Texture2D _heightTex;

    [ContextMenu("SaveSplatMap")]
    public void SaveSplatMap()
    {
        TerrainData data = _terrain.terrainData;

        int width = data.alphamapWidth;
        int height = data.alphamapHeight;
        int layers = data.alphamapLayers;

        int textureCount = Mathf.CeilToInt(layers / 4f);

        Directory.CreateDirectory(_savePathSplat);
        float[,,] alphamaps = data.GetAlphamaps(0, 0, width, height);

        for (int t = 0; t < textureCount; t++)
        {
            Texture2D tex = new Texture2D(width, height, TextureFormat.RGBA32, false);

            Color[] pixels = new Color[width * height];

            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    int i = y * width + x;

                    float r = GetLayer(alphamaps, x, y, t * 4 + 0);
                    float g = GetLayer(alphamaps, x, y, t * 4 + 1);
                    float b = GetLayer(alphamaps, x, y, t * 4 + 2);
                    float a = GetLayer(alphamaps, x, y, t * 4 + 3);

                    pixels[i] = new Color(r, g, b, a);
                }
            }

            tex.SetPixels(pixels);
            tex.Apply();

            byte[] png = tex.EncodeToPNG();
            File.WriteAllBytes($"{_savePathSplat}/splatmap_{transform.position.x}_{transform.position.z}.png", png);
        }
#if UNITY_EDITOR
        UnityEditor.AssetDatabase.Refresh();
#endif

        Debug.Log("Splatmaps exported!");
    }

    //[ContextMenu("GenerateNavQuads")]
    //public void GenerateNavQuads()
    //{
    //    var mesh = _copyObject.GetComponent<MeshFilter>().sharedMesh;
    //    var verts = mesh.vertices;
    //    var gridSize = 64;

    //    for (int z = 0; z < gridSize; z ++)
    //    {
    //        for (int x = 0; x < gridSize; x++)
    //        {
    //            int i0 = z * gridSize + x;

    //            Vector3 p0 = _copyObject.transform.TransformPoint(verts[i0]);

    //            Vector3 normal = _copyObject.transform.TransformDirection(mesh.normals[i0]).normalized;

    //            Vector3 baseForward = Vector3.forward;
    //            Vector3 forward = Vector3.ProjectOnPlane(baseForward, normal).normalized;

    //            if (forward.sqrMagnitude < 0.001f)
    //            {
    //                baseForward = Vector3.right;
    //                forward = Vector3.ProjectOnPlane(baseForward, normal).normalized;
    //            }

    //            Quaternion rot = Quaternion.LookRotation(forward, normal);

    //            GameObject quad = Instantiate(_navQuad);
    //            quad.transform.position = p0;
    //            quad.transform.rotation = rot;
    //        }
    //    }
    //}

    [ContextMenu("ConvertTrees")]
    public void ConvertTrees()
    {
        var data = _terrain.terrainData;

        var trees = data.treeInstances;

        foreach (var tree in data.treeInstances)
        {
            var prefab = data.treePrototypes[tree.prototypeIndex].prefab;

            Vector3 pos = Vector3.Scale(tree.position, data.size) + _terrain.transform.position;

            var go = Instantiate(prefab, pos, Quaternion.Euler(0, tree.rotation * Mathf.Rad2Deg, 0));

            float scale = tree.widthScale;
            go.transform.localScale = Vector3.one * scale;
        }
    }

    [ContextMenu("BakeChunkObjects")]
    public void BakeChunkObjects()
    {
        var allObjects = FindObjectsByType<MapEnviromentObject>(
            FindObjectsInactive.Include,
            FindObjectsSortMode.None
        );
        var chunkMap = new Dictionary<Vector2Int, List<IMapObject>>();
        if (!Directory.Exists(_saveChunkDataPath))
            Directory.CreateDirectory(_saveChunkDataPath);
        foreach (var obj in allObjects)
        {
            if (obj is IMapObject mapObj)
            {
                Vector3 pos = mapObj.Position() - _startPos;
                int chunkX = Mathf.FloorToInt((pos.x + 50f) / 100f);
                int chunkZ = Mathf.FloorToInt((pos.z + 50f) / 100f);
                Vector2Int coord = new Vector2Int(chunkX, chunkZ);

                if (!chunkMap.ContainsKey(coord))
                    chunkMap[coord] = new List<IMapObject>();

                Debug.Log($"Find map object ID : {mapObj.Id()}");

                chunkMap[coord].Add(mapObj);
            }
        }

        for (int z = 0; z < chunksPerSide; z++)
        {
            for (int x = 0; x < chunksPerSide; x++)
            {
                Vector2Int currentCoord = new Vector2Int(x, z);

                if (chunkMap.TryGetValue(currentCoord, out var objectsInChunk))
                {
                    byte[] data = BinaryChunkSerializer.Serialize(objectsInChunk.ToArray());

                    string path = Path.Combine(_saveChunkDataPath, $"Chunk_{x}_{z}.bytes");
                    File.WriteAllBytes(path, data);
                }
            }
        }
#if UNITY_EDITOR
        UnityEditor.AssetDatabase.Refresh();
#endif
    }

    [ContextMenu("Generate Heightmap")]
    public void Generate()
    {
        int size = chunksPerSide * (tileResolution - 1) + 1;
        ushort[,] heights = new ushort[size, size];

        for (int z = 0;  z < size; z++)
        {
            for (int x = 0; x < size; x++)
            {
                var pos = new Vector3(-1000f + x * _distPervertex, 0f, -1000f + z * _distPervertex);

                var Y = _terrain.SampleHeight(pos);
                heights[x, z] = (ushort)(Y / 300f * 65535f);
            }
        }
        HeightmapSerializer.Save($"{_saveHeightPath}/heightmap.bytes", heights);

#if UNITY_EDITOR
        UnityEditor.AssetDatabase.Refresh();
#endif

        Debug.Log($"FAST Heightmap saved: {_savePathSplat} (x)");
    }

    [ContextMenu("GenerateChunk")]
    public void GenerateChunk()
    {
        int width = _buildQuadSize.x;

        for (int z = 0; z < _buildQuadSize.y; z++)
        {
            for (int x = 0; x < width; x++)
            {
                int index = z * width + x;
                var mf = _chunks[index].GetComponent<MeshFilter>();
                _chunks[index].transform.position = new Vector3(_startPos.x + 100f * x, 0f, _startPos.z + 100f * z);
                Mesh mesh = Instantiate(mf.sharedMesh);
                mf.sharedMesh = mesh;

                var verts = mesh.vertices;

                for (int i = 0; i < verts.Length; i++)
                {
                    Vector3 v = verts[i];
                    Vector3 worldPos = mf.transform.TransformPoint(v);
                    float worldHeight = _terrain.SampleHeight(worldPos);

                    v.y = worldHeight - mf.transform.position.y;

                    verts[i] = v;
                }

                mf.sharedMesh.vertices = verts;
                mf.sharedMesh.RecalculateNormals();
                mf.sharedMesh.RecalculateBounds();
            }
        }
    }

    private float GetLayer(float[,,] maps, int x, int y, int layer)
    {
        if (layer >= maps.GetLength(2))
            return 0f;

        return maps[y, x, layer];
    }   
}
