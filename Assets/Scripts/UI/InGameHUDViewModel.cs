using UnityEngine;
using UniRx;
using System;

public class InGameHUDViewModel : IDisposable
{   
    private readonly CompositeDisposable _disposables = new();
    private readonly HealthComponent _health;
    public IReadOnlyReactiveProperty<float> HpNormalized => _hpNormalized;
    public IReadOnlyReactiveProperty<string> HpText => _hpText;

    private readonly FloatReactiveProperty _hpNormalized = new();
    private readonly StringReactiveProperty _hpText = new();

    public IReadOnlyReactiveProperty<float> MpNormalized => _mpNormalized;
    public IReadOnlyReactiveProperty<string> MpText => _mpText;

    private readonly FloatReactiveProperty _mpNormalized = new();
    private readonly StringReactiveProperty _mpText = new();

    public InGameHUDViewModel(Character character)
    {
        _health = character.GetHealth();

        Observable.CombineLatest(_health.CurrentHp, _health.MaxHp, (current, max) => (current, max))
            .Subscribe(stats =>
            {
                _hpNormalized.Value = stats.current / stats.max;
                _hpText.Value = $"{Mathf.RoundToInt(stats.current)} / {Mathf.RoundToInt(stats.max)}";
            })
            .AddTo(_disposables);

        Observable.CombineLatest(_health.CurrentMp, _health.MaxMp, (current, max) => (current, max))
            .Subscribe(stats =>
            {
                _mpNormalized.Value = stats.current / stats.max;
                _mpText.Value = $"{Mathf.RoundToInt(stats.current)} / {Mathf.RoundToInt(stats.max)}";
            })
            .AddTo(_disposables);
    }

    public void Dispose()
    {
        _disposables.Dispose();
    }
}
