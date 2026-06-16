using UnityEngine;

public class EnemyBuildMarker : MonoBehaviour, IMapCreature
{
    public byte Type;
    public ushort Level;
    public bool Elite;

    public CreatureDatabase DataBase;

    public ushort ID;

    public bool Active()
    {
        throw new System.NotImplementedException();
    }

    public (byte, ushort, bool) GetCreatureTypeAndLvl()
    {
        return (Type, Level, Elite);
    }

    public GameObject GetCreatureView()
    {
        throw new System.NotImplementedException();
    }

    public ushort Id() => ID;

    public void InitializeCreature(EnemyRuntimeData data, GameObject view)
    {
        throw new System.NotImplementedException();
    }


    public Vector3 Position() => transform.position;
    public Quaternion Rotation() => transform.rotation;
    public Vector3 Scale() => transform.localScale;

    public void SetActive(bool active)
    {
        throw new System.NotImplementedException();
    }

    public void SetPosition(Vector3 position)
    {
        throw new System.NotImplementedException();
    }

    public void SetRotation(Quaternion rotation)
    {
        throw new System.NotImplementedException();
    }

    public void SetScale(Vector3 scale)
    {
        throw new System.NotImplementedException();
    }

    public Transform Transform()
    {
        throw new System.NotImplementedException();
    }

#if UNITY_EDITOR
    private void OnValidate()
    {
        string newName = DataBase.TypeToName(Type);

        if (gameObject.name != newName)
        {
            gameObject.name = newName;

            UnityEditor.EditorUtility.SetDirty(gameObject);
        }
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawCube(transform.position, Vector3.one);
    }
#endif

    public MapObjectType ObjType() => MapObjectType.Creature;
}
