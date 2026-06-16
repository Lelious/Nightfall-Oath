using System;
using UnityEngine;
using UnityEngine.AddressableAssets;

[Serializable]
public struct MeshData
{
    public string Name;
    public ushort Id;
    public AssetReferenceT<Mesh> meshReference;
    public Material[] SubMeshMaterials;
}
