using UnityEngine;
using TMPro;
using System.Collections.Generic;
using Cysharp.Threading.Tasks;

public class FPSDisplay : MonoBehaviour
{
    [SerializeField] private TextMeshProUGUI _counter;
    [SerializeField] private float textUpdateInterval = 0.3f;
    [SerializeField] private float smoothing = 5f;

    private float _smoothedFps = 60f;

    private void Start()
    {
        DisplayFps().Forget();
    }

    private async UniTaskVoid DisplayFps()
    {
        float textTimer = 0f;

        while (true)
        {
            float dt = Time.unscaledDeltaTime;

            float currentFps = dt > 0f ? 1f / dt : 0f;

            _smoothedFps = Mathf.Lerp(
                _smoothedFps,
                currentFps,
                1f - Mathf.Exp(-smoothing * dt)
            );

            textTimer += dt;
            if (textTimer >= textUpdateInterval)
            {
                textTimer = 0f;

                int roundedFps = Mathf.RoundToInt(_smoothedFps);

                Color color =
                    roundedFps >= 25 ? Color.green :
                    roundedFps >= 15 ? Color.yellow :
                    Color.red;

                string hexColor = ColorUtility.ToHtmlStringRGB(color);

                _counter.text = $"fps: <color=#{hexColor}>{roundedFps}</color>";
            }

            await UniTask.Yield(PlayerLoopTiming.LastPostLateUpdate);
        }
    }
}
