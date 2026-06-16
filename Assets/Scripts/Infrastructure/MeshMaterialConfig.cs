using UnityEngine;

[CreateAssetMenu(fileName = "MeshMaterialConfig", menuName = "World/Mesh Material Config")]
public class MeshMaterialConfig : ScriptableObject
{
    public MeshData[] allMeshes;
}