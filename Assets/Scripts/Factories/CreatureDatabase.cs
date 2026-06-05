using System;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "CreatureDatabase", menuName = "Crops/CreatureDatabase")]
public class CreatureDatabase : ScriptableObject
{
    public List<CreatureObject> prefabs;

    public string TypeToName(byte type) => prefabs.Find(x => x.ID == type).Data.AssetAddress;
}

[Serializable]
public class CreatureObject
{
    public byte ID;
    public EnemyData Data;
}
