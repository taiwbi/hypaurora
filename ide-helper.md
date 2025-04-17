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


    /**
    * @method \App\Models\User user()
    */
    class EmailVerificationRequest extends \Illuminate\Foundation\Auth\EmailVerificationRequest {}
}
```

#### Already existing

These are classes that already exists and I only add a method to them

```php
<?
// This might be a wrong approach
    /*
     * @method static void url(string $location): string
     * @see \Illuminate\Filesystem\FilesystemManager
     */
    class Storage {
```
