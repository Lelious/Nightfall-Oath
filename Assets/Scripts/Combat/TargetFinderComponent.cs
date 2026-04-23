using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TargetFinderComponent : MonoBehaviour
{
    [SerializeField] private List<Enemy> _targets = new();
    [SerializeField] private Transform _targetFrame;
    [SerializeField] private float _maxDistanceToFrame = 10f;
    [SerializeField] private EnemyHealthInfoPannel _infoPannel;

    private bool _isAutotargetMode;
    private Enemy _possibleTarget;

    private void Awake()
    {
        _isAutotargetMode = true;
        StartCoroutine(SetTargetFrame());
    }

    private void LateUpdate()
    {
        if (_possibleTarget == null) return;

        _targetFrame.position = _possibleTarget.transform.position;
        _targetFrame.localScale = Vector3.one * _possibleTarget.GetCreatureFrameScale();
    }

    public Enemy GetPossibleTarget(Vector3 position, float distance)
    {
        return _possibleTarget;
    }

    public void SetTarget(Enemy enemy)
    {
        _possibleTarget = enemy;
        _targetFrame.gameObject.SetActive(_possibleTarget != null);
        SetAutotargetMode(false);
    }

    public void SetAutotargetMode(bool autotarget)
    {
        _isAutotargetMode = autotarget;
    }

    public void StopAutotarget()
    {
        _isAutotargetMode = false;
        _infoPannel.InitializeEnemyHealth(_possibleTarget, _isAutotargetMode);
    }

    private void FindTarget()
    {
        _possibleTarget = null;

        foreach (var target in _targets)
        {
            if (target == null || !target.GetHealth().IsAlive()) continue;

            var dist = Vector3.Distance(transform.position, target.transform.position);

            if (dist > _maxDistanceToFrame) continue;

            if (_possibleTarget == null)
            {
                _possibleTarget = target;
                continue;
            }

            var oldDist = Vector3.Distance(transform.position, _possibleTarget.transform.position);

            if (dist < oldDist)
            {
                if (target.GetHealth().IsAlive())
                {
                    _possibleTarget = target;
                }
            }
        }
        _infoPannel.InitializeEnemyHealth(_possibleTarget, _isAutotargetMode);
    }

    private IEnumerator SetTargetFrame()
    {
        while (true)
        {
            if(_isAutotargetMode)
            {
                FindTarget();
                _targetFrame.gameObject.SetActive(_possibleTarget != null);
                _infoPannel.InitializeEnemyHealth(_possibleTarget, _isAutotargetMode);
            }
            else
            {
                if(_possibleTarget == null)
                {
                    _isAutotargetMode = true;
                    _infoPannel.InitializeEnemyHealth(_possibleTarget, _isAutotargetMode);
                }
                else
                {
                    if (Vector3.Distance(transform.position, _possibleTarget.transform.position) > _maxDistanceToFrame * 2f)
                    {
                        _possibleTarget = null;
                        _isAutotargetMode = true;
                        _infoPannel.InitializeEnemyHealth(_possibleTarget, _isAutotargetMode);
                    }
                }
            }
            yield return new WaitForSeconds(0.3f);
        }
    }
}
