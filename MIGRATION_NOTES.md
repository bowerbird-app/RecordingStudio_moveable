# Migration notes for Moveable 4.0

Moveable 4.0 requires RecordingStudio `>= 6.1.0` and FlatPack `>= 0.1.315`. It drops `full_page_layout`, `RecordingStudio::UsesDefaultLayout`, and `recording_studio_page_nav`.

Notes for Moveable 3.0 and RecordingStudio 4.2 stay in `CHANGELOG.md` and `docs/recording_studio_moveable/UPGRADING.md`.

## Host steps

1. Point the bundle at RecordingStudio `v6.1.0` and FlatPack commit `1fcbafe94f8eb118f0a22182f63f5110fcc97a56` (`0.1.319`). Tag `v0.1.315` is the newest FlatPack tag and satisfies the gemspec floor.

   ```ruby
   gem "recording_studio", ">= 6.1.0", github: "bowerbird-app/RecordingStudio", tag: "v6.1.0"
   gem "flat_pack", github: "bowerbird-app/flatpack", ref: "1fcbafe94f8eb118f0a22182f63f5110fcc97a56"
   gem "recording_studio_moveable", "~> 4.0"
   gem "view_component", ">= 4.14", "< 5"
   ```

2. If a sibling gem still requires `recording_studio` below 5, use a newer tag when one exists. Accessible `v0.21.0`, Metrics `v0.6.1`, and Internationalization `v0.1.7` still declare that older requirement. Trashable `v0.12.0` allows `>= 6.1.0`. This repo pins Accessible `v0.18.0`, Trashable `v0.11.0`, Metrics `v0.2.0`, and Internationalization `v0.1.2`, and loads `test/support/widen_recording_studio_requirement.rb` before `gemspec` so Bundler rewrites those requirements to `>= 6.1.0`. That file is a development workaround. It is not a host runtime dependency.

   Accessible `v0.18.0` also cannot render its manage screens on FlatPack `0.1.319`. `home/user_invites.html.erb` passes `style:` to `FlatPack::Card::Component`. `recording_accesses/index.html.erb` and `recording_accesses/_form.html.erb` pass `anchor_href:` to `FlatPack::PageNav::Component` and `style:` to Card. FlatPack raises `ArgumentError`. Accessible `v0.21.0` and main `98e68a45296e052df373466cca6a5d3431c7f9bf` still pass `style: :default` to Card in `user_invites.html.erb`. The dummy skips those paths until Accessible drops the removed keywords. The home, overview, methods, and email template pages still render.

3. Replace `config.full_page_layout` with `config.layout`.

   ```ruby
   RecordingStudioMoveable.configure do |config|
     config.layout = nil
   end
   ```

   `nil` uses `RecordingStudio.configuration.layout`, then `"recording_studio/default_layout"`. `false` renders no layout. A callable is `->(controller:) { "application" }`.

4. Remove `include RecordingStudio::UsesDefaultLayout` and `layout "recording_studio/default_layout"`. The engine controller already calls `recording_studio_layout`.

5. On full-page views, set `content_for :title` and `content_for :subtitle`. Call `flat_pack_page_nav` for back and close. Call `register_page_nav` for page actions. Do not render a second `FlatPack::PageTitle` in the body. Modal move responses still render that title inside the dialog.

6. Replace `FlatPack::Card::Component.new(style: ...)` with `background:`, `border:`, and `shadow:`.

7. Load `flat_pack/variables`, `flat_pack/application`, and `flat_pack/rich_text` before the host Tailwind sheet.

8. Run the checks.

   ```bash
   bundle exec rake test
   bundle exec rake recording_studio:check_layouts
   bundle exec rubocop
   ```

Move rules are unchanged. A recording still cannot move under itself or a descendant. The write path still calls `RecordingStudio.assert_parent_allowed!` and re-checks authorization. Hierarchy and root id updates stay in one transaction. Built-in Accessible mode and `authorization_hook` (`true`, `false`, or `nil`) stay. An inaccessible source still returns 404.
