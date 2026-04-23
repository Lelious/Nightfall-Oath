using System.Collections.Generic;
using System.IO;
using System.Linq;
using Unity.AI.Navigation;
using UnityEditor;
using UnityEngine;

[ExecuteAlways]
public class MeshCopier : MonoBehaviour
{
    [SerializeField] private Terrain _terrain;
    [SerializeField] private GameObject _copyObject;
    [SerializeField] private Texture2D _heightMap;
    [SerializeField] private Vector3 _startPos;
    [SerializeField] private Vector3 _startPosVertex;
    [SerializeField] private NavMeshSurface _navSurf;

    public float minHeight, maxHeight;
    public int chunkX;
    public int chunkY;
    public int tileResolution = 64;
    public int chunksPerSide = 20;
    public float chunkSize = 100f;

    [SerializeField] private int highestX, highestZ = 0;
    private const float _distPervertex = 1.5873f;
    private string _savePathSplat = "Assets/Chunks/Splatmaps/";
    private string _saveHeightPath = "Assets/StreamingAssets/";
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

    [ContextMenu("ConvertRocks")]
    public void ConvertRocks()
    {
        var data = _terrain.terrainData;

        var rock = data.treeInstances;

        foreach (var tree in data.treeInstances)
        {
            var prefab = data.treePrototypes[tree.prototypeIndex].prefab;

            Vector3 pos = Vector3.Scale(tree.position, data.size) + _terrain.transform.position;

            var go = Instantiate(prefab, pos, Quaternion.Euler(0, tree.rotation * Mathf.Rad2Deg, 0));

            float scale = tree.widthScale;
            go.transform.localScale = Vector3.one * scale;
        }
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
        HeightmapSerializer.Save($"{_saveHeightPath}/heightmap.bin", heights);

#if UNITY_EDITOR
        UnityEditor.AssetDatabase.Refresh();
#endif

        Debug.Log($"FAST Heightmap saved: {_savePathSplat} (x)");
    }

    [ContextMenu("GenerateChunk")]
    public void GenerateChunk()
    {
        _copyObject.transform.position = _startPos;
        var mf = _copyObject.GetComponent<MeshFilter>();

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

    private float GetLayer(float[,,] maps, int x, int y, int layer)
    {
        if (layer >= maps.GetLength(2))
            return 0f;

        return maps[y, x, layer];
    }
}
