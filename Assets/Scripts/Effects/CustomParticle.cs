using System.Collections.Generic;
using UnityEngine;
using Zenject;

[RequireComponent(typeof(ParticleSystem))]
public class CustomParticle : MonoBehaviour
{
    [SerializeField] private AnimationCurve brightnessCurve = AnimationCurve.Linear(0, 1, 1, 0);
    [SerializeField] private ParticleSystem _ps;
    [SerializeField] private CustomLight _cl;

    private Transform _psTransform;
    private ParticleSystem.Particle[] _singleParticleBuffer;
    private bool _isWorldSpace;
    private List<Vector4> _singleCustomDataBuffer = new List<Vector4>(1);

    private CustomLightService _lightService;

    [Inject]
    public void Construct(CustomLightService lightService)
    {
        _lightService = lightService;
        _psTransform = transform;
        _isWorldSpace = _ps.main.simulationSpace == ParticleSystemSimulationSpace.World;
        _singleParticleBuffer = new ParticleSystem.Particle[1];
    }

    private void OnEnable()
    {
        _cl.gameObject.SetActive(true);
    }

    void LateUpdate()
    {
        if (_lightService == null || _ps == null) return;

        int aliveCount = _ps.GetParticles(_singleParticleBuffer, 1);

        if (aliveCount > 0)
        {
            ParticleSystem.Particle p = _singleParticleBuffer[0];

            if (_cl != null)
            {
                if (!_cl.gameObject.activeSelf)
                    _cl.gameObject.SetActive(true);
                Vector3 worldPos = _isWorldSpace ? p.position : _psTransform.TransformPoint(p.position);
                _cl.transform.position = worldPos;
                _singleCustomDataBuffer.Clear();
                _ps.GetCustomParticleData(_singleCustomDataBuffer, ParticleSystemCustomData.Custom1);
                Vector4 customData = _singleCustomDataBuffer[0];

                float normalizedAge = 1.0f - (p.remainingLifetime / p.startLifetime);
                float hdrBrightness = customData.z;

                _cl.SetData(new Vector4(p.GetCurrentSize(_ps) * hdrBrightness * 0.2f, hdrBrightness, 8f, 1f));
                _cl.SetColor(p.GetCurrentColor(_ps));
            }
        }
        else
        {
            ReleaseLight();
        }
    }

    private void ReleaseLight()
    {
        if (_cl != null)
        {
            if (_lightService != null)
            {
                _cl.gameObject.SetActive(false);
            }
        }
    }

    private void OnDestroy()
    {
        ReleaseLight();
    }

    private void OnDisable()
    {
        ReleaseLight();
    }
}
