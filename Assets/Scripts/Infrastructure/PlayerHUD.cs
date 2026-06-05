using System.Collections.Generic;
using UniRx;
using UniRx.Triggers;
using UnityEngine;
using UnityEngine.UI;
using Zenject;

public class PlayerHUD : MonoBehaviour
{
    [SerializeField] private EnemyHealthInfoPannel _infoPannel;
    [SerializeField] private FixedJoystick _joystick;
    [SerializeField] private List<ActionButton> _actionButtons;

    private readonly CompositeDisposable _disposables = new();
    private InputService _inputService; 

    [Inject]
    public void Construct(InputService inputService)
    {
        _inputService = inputService;

        Observable.EveryUpdate()
            .Subscribe(_ =>
            {
                _inputService.SetMovementInput(_joystick.Direction);
            })
            .AddTo(_disposables);

        foreach (var button in _actionButtons)
        {
            button.gameObject.AddComponent<ObservablePointerDownTrigger>()
                .OnPointerDownAsObservable()
                .Subscribe(_ => _inputService.SetActiveSpell(button.SpellId))
                .AddTo(_disposables);

            button.gameObject.AddComponent<ObservablePointerUpTrigger>()
                .OnPointerUpAsObservable()
                .Subscribe(_ => _inputService.SetActiveSpell(0))
                .AddTo(_disposables);

            button.gameObject.AddComponent<ObservablePointerExitTrigger>()
                .OnPointerExitAsObservable()
                .Subscribe(_ => _inputService.SetActiveSpell(0))
                .AddTo(_disposables);
        }       

        Observable.CombineLatest(
            _inputService.CurrentTarget,
            _inputService.IsAutotarget,
            (target, isAuto) => (target, isAuto))
            .Subscribe(result => OnTargetChanged(result.target, result.isAuto))
            .AddTo(_disposables);
    }

    private void OnTargetChanged(Enemy newTarget, bool isAutotarget)
    {
        if (newTarget == null)
        {
            _infoPannel.HidePannel();
            return;
        }

        _infoPannel.InitializeEnemyHealth(newTarget, isAutotarget);       
    }

    private void OnDestroy()
    {
        _disposables.Dispose();
        _inputService?.SetMovementInput(Vector2.zero);
    }
}
