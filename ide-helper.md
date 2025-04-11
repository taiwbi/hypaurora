This is the IDE Helper snippets that I need but is not available in `` by default:

### File: `_ide_helper.php`

```php
<?

namespace {
  /**
  * Get the available auth instance.
  *
  * @param  string|null  $guard
  * @return \Illuminate\Auth\AuthManager|\Illuminate\Contracts\Auth\Factory|\Illuminate\Contracts\Auth\Guard|\Illuminate\Contracts\Auth\StatefulGuard
  */
  function auth($guard = null) { }

    /**
     * Get the evaluated view contents for the given view.
     *
     * @param  string|null  $view
     * @param  \Illuminate\Contracts\Support\Arrayable|array  $data
     * @param  array  $mergeData
     * @return Illuminate\View\View|($view is null ? \Illuminate\Contracts\View\Factory : \Illuminate\Contracts\View\View)
     */
    function view($view = null, $data = [], $mergeData = []) {}
}
```
