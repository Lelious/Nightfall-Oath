using UnityEngine;

public interface IMapCreature : IMapObject
{
    public void InitializeCreature(EnemyRuntimeData data, GameObject view);
    public (byte, ushort, bool) GetCreatureTypeAndLvl();
    public GameObject GetCreatureView();
}
