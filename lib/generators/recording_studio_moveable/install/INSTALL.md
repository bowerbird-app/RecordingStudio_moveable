===============================================================================

RecordingStudioMoveable has been installed successfully!

The engine has been mounted at /recording_studio_moveable in your application.

The default authorization mode expects `recording_studio_accessible` to be installed.
If you want built-in move authorization instead of a custom authorization hook:
1. Add `gem "recording_studio_accessible", "~> 0.3"` to your Gemfile
2. Run `bin/rails generate recording_studio_accessible:install`
3. Run `bin/rails generate recording_studio_accessible:migrations`
4. Run `bin/rails db:migrate`
5. Enable the `:accessible` capability on root recordables with `RecordingStudio.enable_capability(:accessible, on: self)`
6. Expose your acting principal through `Current.actor` or configure
   `RecordingStudioMoveable.configure { |config| config.current_actor_resolver = ->(controller:) { controller.current_user } }`

In built-in mode, RecordingStudioMoveable resolves roles through Recording Studio Accessible's public query APIs, even when Accessible is running in compatibility mode on top of existing `recording_studio` access tables.

If you use Tailwind CSS:
1. Run 'bin/rails tailwindcss:build' to rebuild your CSS with RecordingStudioMoveable styles

To use the engine:
1. Start your Rails server
2. Visit http://localhost:3000/recording_studio_moveable

===============================================================================
