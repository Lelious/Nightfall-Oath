using UnityEngine;

public class TESTNORMALS : MonoBehaviour
{
    void Start()
    {
        var mf = GetComponent<MeshFilter>();
        mf.mesh.RecalculateNormals();
        mf.mesh.RecalculateTangents();
        mf.mesh.RecalculateBounds();
    }
}
