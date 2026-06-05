using TMPro;
using UniRx;
using UnityEngine;
using UnityEngine.UI;
using Zenject;

public class UIHealthAndManaService : MonoBehaviour
{
    [SerializeField] private TextMeshProUGUI _expText;
    [SerializeField] private TextMeshProUGUI _healthText;
    [SerializeField] private TextMeshProUGUI _manaText;

    [SerializeField] private Image _hpBar;
    [SerializeField] private Image _mpBar;
    [SerializeField] private Image _expBar;

    private Material _hpMaterial;
    private Material _manaMaterial;
    private Material _expMaterial;

    private readonly CompositeDisposable _disposables = new();
    private InGameHUDViewModel _viewModel;

    [Inject]
    public void Construct(InGameHUDViewModel viewModel)
    {
        _viewModel = viewModel;

        _hpMaterial = new Material(_hpBar.material);
        _hpBar.material = _hpMaterial;
        _manaMaterial = new Material(_mpBar.material);
        _mpBar.material = _manaMaterial;
        _manaMaterial.SetFloat("_NoiseOffset", 0.5f);
        //_expMaterial = new Material(_expBar.material);
        //_expBar.material = _expMaterial;

        Bind();
    }

    private void Bind()
    {
        _viewModel.HpNormalized
            .Subscribe(value => _hpMaterial.SetFloat("_Fill", value))
            .AddTo(_disposables);

        _viewModel.HpText
            .Subscribe(text => _healthText.text = $"{_viewModel.HpText}")
            .AddTo(_disposables);

        _viewModel.MpNormalized
            .Subscribe(value => _manaMaterial.SetFloat("_Fill", value))
            .AddTo(_disposables);

        _viewModel.MpText
            .Subscribe(text => _manaText.text = $"{_viewModel.MpText}")
            .AddTo(_disposables);
    }

    private void OnDestroy()
    {
        _disposables.Dispose();
    }
}
