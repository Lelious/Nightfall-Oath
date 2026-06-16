using UnityEngine;
using TMPro;
using System.Collections.Generic;
using System;

public class FloatingTextService : MonoBehaviour
{
    [SerializeField] private Material _normal, _critical, _character, _healing;
    [SerializeField] private TextMeshPro _textPrefab;
    [SerializeField] private int _poolSize;
    [SerializeField] private float _scrollSpeed;
    [SerializeField] private float _lifeTime;
    [SerializeField] private float _horizontalOffset;
    [SerializeField] private float _initialSize = 0.04f;

    [Tooltip("Множитель масштаба (Размера) текста")]
    [SerializeField] private AnimationCurve _scaleCurve = AnimationCurve.Linear(0, 1, 1, 1);

    [Tooltip("Прозрачность текста (Альфа-канал от 0 до 1)")]
    [SerializeField] private AnimationCurve _alphaCurve = AnimationCurve.EaseInOut(0, 1, 1, 0);

    private Transform _cameraTransform;
    private bool _initialized;
    private Queue<FloatingText> _floatingTextPool = new Queue<FloatingText>();
    private List<FloatingText> _activePool = new List<FloatingText>();

    private void Awake()
    {
        for (int i = 0; i < _poolSize; i++)
        {
            _floatingTextPool.Enqueue(CreateFloatingText());
        }       
        _initialized = true;
    }

    public void AddFloatingText(int value, Vector3 position, DamageSource source)
    {
        _floatingTextPool.TryDequeue(out var text);

        if (text == null)
            text = CreateFloatingText();

        text.Lifetime = _lifeTime;
        text.ScrollSpeed = _scrollSpeed;
        text.Source = source;

        float side = UnityEngine.Random.Range(-_horizontalOffset, _horizontalOffset);
        float direction = side < 0 ? -1f : 1f;

        bool player = false;
        float currentSize = _initialSize;

        switch (source)
        {
            case DamageSource.Creature:
                text.Text.fontSharedMaterial = _normal;
                text.Text.SetText("{0}", value);
                break;

            case DamageSource.Player:
                text.Text.fontSharedMaterial = _character;
                text.Text.SetText("{0}", value);
                currentSize *= 0.9f;
                player = true;
                break;

            case DamageSource.Healing:
                text.Text.fontSharedMaterial = _healing;
                text.Text.SetText("{0}", value);
                break;

            case DamageSource.Critical:
                text.Text.fontSharedMaterial = _critical;
                text.Text.SetText("{0}!", value);
                currentSize *= 1.3f;
                break;

            case DamageSource.CriticalPlayer:
                text.Text.fontSharedMaterial = _critical;
                text.Text.SetText("{0}!", value);
                currentSize *= 1.3f;
                player = true;
                break;
        }

        text.BaseScale = Vector3.one * currentSize;
        text.Object.transform.localScale = text.BaseScale;
        text.OffsetX = _horizontalOffset * direction;
        float offsetY = player ? -1.0f : 1.0f;
        text.BasePosition = new Vector3(position.x + direction, position.y + offsetY, position.z);

        if (_cameraTransform == null)
        {
            _cameraTransform = Camera.main.transform;
        }

        text.ProcessPosition(0f, _lifeTime, _scaleCurve.Evaluate(0f), _alphaCurve.Evaluate(0f), _cameraTransform);
        text.Object.SetActive(true);

        _activePool.Add(text);
    }

    private FloatingText CreateFloatingText()
    {
        var text = Instantiate(_textPrefab, transform);
        text.gameObject.SetActive(false);
        var floatingText = new FloatingText();
        floatingText.Text = text;
        floatingText.ScrollSpeed = _scrollSpeed;
        floatingText.Object = text.gameObject;
        
        return floatingText;
    }

    private void LateUpdate()
    {
        if (!_initialized || _activePool.Count == 0) return;

        float delta = Time.deltaTime;

        for (int i = _activePool.Count - 1; i >= 0; i--)
        {
            FloatingText textElement = _activePool[i];

            float progress = Mathf.Clamp01(1f - (textElement.Lifetime / _lifeTime));

            float currentScale = _scaleCurve.Evaluate(progress);
            float currentAlpha = _alphaCurve.Evaluate(progress);

            textElement.ProcessPosition(delta, _lifeTime, currentScale, currentAlpha, _cameraTransform);

            if (textElement.Lifetime <= 0)
            {
                textElement.Object.SetActive(false);
                _floatingTextPool.Enqueue(textElement);
                _activePool.RemoveAt(i);
            }
        }
    }
}

public enum DamageSource
{
    Creature,
    Player,
    Healing,
    Critical,
    CriticalPlayer
}
