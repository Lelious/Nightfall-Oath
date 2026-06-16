using System;
using System.Collections.Generic;
using UniRx;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem;
using Zenject;

public class ScreenTargetSelector : MonoBehaviour, IDisposable
{
    private readonly CompositeDisposable _disposables = new();
    private InputService _inputService;
    private Camera _mainCamera;

    [Inject]
    public void Construct(InputService inputService)
    {
        _inputService = inputService;

        Observable.EveryUpdate()
            .Where(_ => CheckClickPerformed())
            .Where(_ => !IsPointerOverUI())
            .Subscribe(_ => TrySelectTarget())
            .AddTo(_disposables);
    }

    private bool IsPointerOverUI()
    {
        if (EventSystem.current == null || Pointer.current == null)
            return false;

        PointerEventData eventDataCurrentPosition = new PointerEventData(EventSystem.current);
        eventDataCurrentPosition.position = Pointer.current.position.ReadValue();

        List<RaycastResult> results = new List<RaycastResult>();
        EventSystem.current.RaycastAll(eventDataCurrentPosition, results);

        foreach (var result in results)
        {
            if (result.gameObject.layer == LayerMask.NameToLayer("UI"))
            {
                return true;
            }
        }

        return false;
    }

    private bool CheckClickPerformed()
    {
        if (Pointer.current == null) return false;

        return Pointer.current.press.wasPressedThisFrame;
    }

    private void TrySelectTarget()
    {
        Debug.Log("Raycast");
        if (_mainCamera == null)
        {
            _mainCamera = Camera.main;
        }

        if (_mainCamera == null) return;
        Vector2 screenPosition = Pointer.current.position.ReadValue();
        Ray ray = _mainCamera.ScreenPointToRay(screenPosition);

        if (Physics.Raycast(ray, out RaycastHit hit, 100f))
        {           
            if (hit.collider.TryGetComponent<Enemy>(out var enemy))
            {
                _inputService.SetTarget(enemy, false);
            }
        }
    }
    public void Dispose()
    {
        _disposables.Dispose();
    }
}
