===============================================================================

RecordingStudioMoveable has been installed successfully!

The engine has been mounted at /recording_studio_moveable in your application.

The default authorization mode expects `recording_studio_accessible` to be installed.
If you want built-in access checks instead of a custom authorization hook:
1. Add `gem "recording_studio_accessible"` to your Gemfile
2. Run `bin/rails generate recording_studio_accessible:install`
3. Run `bin/rails generate recording_studio_accessible:migrations`
4. Run `bin/rails db:migrate`
5. Configure your root recordables with `RecordingStudioAccessible::AllowsAccessibleChildren`
6. Expose your acting principal through `Current.actor` or configure
   `RecordingStudioMoveable.configure { |config| config.current_actor_resolver = ->(controller:) { controller.current_user } }`

If you use Tailwind CSS:
1. Run 'bin/rails tailwindcss:build' to rebuild your CSS with RecordingStudioMoveable styles

To use the engine:
1. Start your Rails server
2. Visit http://localhost:3000/recording_studio_moveable

===============================================================================
