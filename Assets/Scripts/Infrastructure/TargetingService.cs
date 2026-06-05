using System.Collections.Generic;
using UnityEngine;

public class TargetingService
{
    private Character _character;
    private List<Enemy> _enemies = new();
    private const float MAX_DISTANCE = 20f;   
    private Enemy _possibleTarget;
    private float _lastDist;
    public Character GetCharacter() => _character;

    public void SetCharacter(Character character)
    {
        _character = character;
    }

    public void AddEnemyToTargeting(Enemy enemy)
    {
        _enemies.Add(enemy);
    }

    public void RemoveEnemyFromTargeting(Enemy enemy)
    {
        _enemies.Remove(enemy);
    }

    public Enemy FindTarget(Vector3 position)
    {
        _possibleTarget = null;
        _lastDist = 0f;
        foreach (var target in _enemies)
        {
            if (target == null || !target.GetHealth().IsAlive()) continue;

            var dist = Vector3.Distance(position, target.transform.position);

            if (dist > MAX_DISTANCE) continue;

            if (_possibleTarget == null)
            {
                _possibleTarget = target;
                _lastDist = dist;
                continue;
            }   
            else
            {
                if(_lastDist > dist)
                {
                    _lastDist = dist;
                    _possibleTarget = target;
                }
            }
        }

        return _possibleTarget;
    }
}
