using System.Collections.Generic;
using UnityEngine;
using DG.Tweening;

public class Dungeon : MonoBehaviour
{
    [SerializeField] private List<MeshRenderer> _objectsToFade;

    private MaterialPropertyBlock _block;
    private float _currentFadeValue = 0f;
    private Tween _fadeTween;

    private void Start()
    {
        _block = new MaterialPropertyBlock();
    }

    private void OnTriggerEnter(Collider other)
    {
        if(other.TryGetComponent<Character>(out _))
        {
            FadeClippingObjects(true);
        }
    }

    private void OnTriggerExit(Collider other)
    {
        if (other.TryGetComponent<Character>(out _))
        {
            FadeClippingObjects(false);
        }
    }

    private void FadeClippingObjects(bool fade)
    {
        _fadeTween.Complete();

        _fadeTween = DOTween.To(() => _currentFadeValue, x => _currentFadeValue = x, fade == true ? 1f : 0f, 0.5f).OnUpdate(() => { ApplyFadeChanges(); });     
    }

    private void ApplyFadeChanges()
    {
        foreach (var item in _objectsToFade)
        {
            item.GetPropertyBlock(_block);
            _block.SetFloat("_Fade", _currentFadeValue);
            item.SetPropertyBlock(_block);
        }
    }
}
