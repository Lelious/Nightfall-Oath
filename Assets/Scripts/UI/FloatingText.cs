using System;
using TMPro;
using UnityEngine;

[Serializable]
public class FloatingText
{
    public TextMeshPro Text;
    public Vector3 BaseScale;
    public Vector3 BasePosition;
    public float OffsetX;
    public float Lifetime;
    public float ScrollSpeed;
    public GameObject Object;
    public DamageSource Source;

    public void ProcessPosition(float delta, float maxLifetime, float scaleCurveValue, float alphaCurveValue, Transform cameraTransform)
    {
        Vector3 yDir = Vector3.zero;
        bool isCritical = Source == DamageSource.Critical || Source == DamageSource.CriticalPlayer;

        switch (Source)
        {
            case DamageSource.Player:
            case DamageSource.CriticalPlayer:
                yDir = new Vector3(0, -1, 0);
                break;
            default:
                yDir = new Vector3(0, 1, 0);
                break;
        }

        Lifetime -= delta;

        float t = Mathf.Clamp01(1f - (Lifetime / maxLifetime));
        float easeOutX = 1f - (1f - t) * (1f - t);
        float currentX = OffsetX * easeOutX;
        float easeInY = t * t * t * t;
        float currentY = easeInY * ScrollSpeed;

        Vector3 rightDirection = cameraTransform.right;

        Text.transform.position = BasePosition + (rightDirection * currentX) + (yDir * currentY);
        Text.transform.rotation = cameraTransform.rotation;

        float finalScaleModifier = scaleCurveValue;

        if (isCritical)
        {
            float punchElement = Mathf.Sin(t * Mathf.PI * 3f) * Mathf.Clamp01(1f - t * 4f) * 0.4f;
            finalScaleModifier = scaleCurveValue + punchElement;
        }

        Text.transform.localScale = BaseScale * finalScaleModifier;
        Text.color = new Color(Text.color.r, Text.color.g, Text.color.b, alphaCurveValue);
    }
}
