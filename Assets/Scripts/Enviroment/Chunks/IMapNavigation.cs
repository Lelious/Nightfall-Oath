using System.Collections.Generic;
using UnityEngine.AI;

public interface IMapNavigation : IMapObject
{
    public bool HasNavigationMeshes();
    public void FillNavSources(List<NavMeshBuildSource> targetList);
}
