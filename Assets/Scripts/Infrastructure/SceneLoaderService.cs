using Cysharp.Threading.Tasks;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using UnityEngine.ResourceManagement.ResourceProviders;
using UnityEngine.SceneManagement;

public class SceneLoaderService
{
    private AsyncOperationHandle<SceneInstance> _previousScene;
    private AsyncOperationHandle<SceneInstance> _nextScene;

    public async UniTask LoadScene(string sceneName)
    {
        await Addressables.InitializeAsync().ToUniTask();
        _previousScene = _nextScene;
        _nextScene = Addressables.LoadSceneAsync(sceneName, LoadSceneMode.Additive, false);
        await _nextScene.ToUniTask();
    }

    public async void SwitchScenes(string sceneName = "")
    {
        if (_nextScene.IsDone)
        {
            await _nextScene.Result.ActivateAsync().ToUniTask();

            if(_previousScene.IsValid())
            {
                await Addressables.UnloadSceneAsync(_previousScene).ToUniTask();
            }
            else if(sceneName != "")
            {
                await SceneManager.UnloadSceneAsync(sceneName).ToUniTask();
            }              
        }
    }
}
