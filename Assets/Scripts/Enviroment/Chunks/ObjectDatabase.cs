using System;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "ObjectDatabase", menuName = "Crops/ObjectDatabase")]
public class ObjectDatabase : ScriptableObject
{
    public List<MapObject> prefabs;

    [ContextMenu("Fill ID")]
    public void FillID()
    {
        foreach (var item in prefabs)
        {
            var map = item.Prefab.GetComponent<IMapObject>();
            item.ID = map.Id();
            item.ObjType = map.ObjType();
        }
    }
}

[Serializable]
public class MapObject
{
    public ushort ID;
    public MapObjectType ObjType;
    public GameObject Prefab;
}
