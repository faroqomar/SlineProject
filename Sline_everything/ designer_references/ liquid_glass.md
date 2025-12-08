https://berkaypng.medium.com/recreating-the-ios-26-liquid-glass-ui-with-flutter-a-complete-guide-f6b7c505529c

Our implementation leverages Flutter’s platform channel architecture combined with platform views to embed genuine UIKit components directly into the Flutter widget tree. Here’s how the magic happens:

Alert Dialog
// Flutter side - Clean, familiar API
AdaptiveAlertDialog.show(
  context: context,
  title: 'Authentication Required',
  message: 'Use this code to complete your authentication.',
  icon: 'lock.shield.fill',
  
  iconSize: 48,
  iconColor: Colors.blue,
  oneTimeCode: '987654',
  actions: [
    AlertAction(
      title: 'Copy & Continue',
      onPressed: () {
        debugPrint('Copy & Continue pressed');
      },
      style: AlertActionStyle.primary,
    ),
    AlertAction(
      title: 'Cancel',
      onPressed: () {
        debugPrint('Cancel pressed');
      },
      style: AlertActionStyle.cancel,
    ),
  ],
);
Press enter or click to view image in full size

Flutter iOS 26 Liquid Glass Alert Dialog
Under the hood, this triggers a method channel call that serializes the alert parameters and sends them to the native iOS platform code.

Native Implementation: Where the Real Magic Happens
On the iOS side, we create authentic UIAlertController instances with iOS 26's liquid glass materials:

// iOS Implementation - Real UIAlertController with liquid glass
let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

// Apply authentic iOS 26 liquid glass effects
alert.view.layer.cornerRadius = 28.0  // 13pt with 2x scale factor
alert.view.layer.cornerCurve = .continuous

// Use systemThinMaterial for authentic blur
if #available(iOS 15.0, *) {
  let blurEffect = UIBlurEffect(style: isDark ? .systemThinMaterialDark : .systemThinMaterialLight)
  let blurView = UIVisualEffectView(effect: blurEffect)
  blurView.frame = alert.view.bounds
  blurView.layer.cornerRadius = 28.0
  blurView.layer.cornerCurve = .continuous
  alert.view.insertSubview(blurView, at: 0)
}
This approach delivers pixel-perfect native fidelity while maintaining Flutter’s declarative development experience. The result is alert dialogs that are indistinguishable from those in native iOS 26 apps, complete with authentic material effects, proper corner curves, and dynamic theme adaptation.

Popup Menu — Native Dropdown Menus
Popup menu is a native component that allows users to select from a menu that opens from a button. It automatically adapts to platform-appropriate appearance on iOS and macOS.

Press enter or click to view image in full size

Flutter iOS 26 Liquid Glass Popup Menu
// Simple popup menu example
AdaptivePopupMenuButton.text<String>(
  label: 'File',
  items: const [
    AdaptivePopupMenuItem(
      label: 'New',
      icon: 'doc.badge.plus',
      value: 'new',
    ),
    AdaptivePopupMenuItem(
      label: 'Open',
      icon: 'folder',
      value: 'open',
    ),
    AdaptivePopupMenuDivider(),
    AdaptivePopupMenuItem(
      label: 'Save',
      icon: 'square.and.arrow.down',
      value: 'save',
    ),
    AdaptivePopupMenuItem(
      label: 'Save As...',
      icon: 'square.and.arrow.down.on.square',
      value: 'save_as',
    ),
    AdaptivePopupMenuDivider(),
    AdaptivePopupMenuItem(
      label: 'Close',
      icon: 'xmark',
      value: 'close',
    ),
  ],
  onSelected: (index, item) {
    setState(() {
      _selectedAction = item.label;
      _selectedValue = item.value ?? '';
    });
  },
  buttonStyle: PopupButtonStyle.bordered,
),
Button — Native Liquid Glass Buttons
Native buttons with iOS 26 liquid glass effects that automatically adapt to platform design guidelines. Available in multiple styles with SF Symbol icon support.

Press enter or click to view image in full size

Flutter iOS 26 Liquid Glass Buttons
AdaptiveButton(
  style: AdaptiveButtonStyle.prominentGlass,
  textColor: Colors.white,
  onPressed: () {},
  label: 'Click Me',
),

// Icon-only button
AdaptiveButton.sfSymbol(
  style: AdaptiveButtonStyle.prominentGlass,
  onPressed: () {},
  sfSymbol: SFSymbol('heart.fill', size: 20),
),

// With custom widget
AdaptiveButton.child(
  child: Widget,
  style: AdaptiveButtonStyle.prominentGlass,
  onPressed: () {},
),
Tab Bar — Native Bottom Navigation
Native tab bar component that provides iOS-style bottom navigation with liquid glass effects and advanced layout options. Integrates seamlessly with Flutter TabBarView for smooth page transitions.

Press enter or click to view image in full size

Flutter iOS 26 Liquid Glass Bottom Navigation Bar
AdaptiveScaffold(
    title: 'Tabbar Demos',
    selectedIndex: _selectedIndex,
    onDestinationSelected: (index) {
      setState(() {
        if (kDebugMode) {
          print('Index selected: $index');
        }
        _selectedIndex = index;
      });
    },
    destinations: [
      AdaptiveNavigationDestination(
        icon: PlatformInfo.isIOS26OrHigher()
            ? "house.fill"
            : PlatformInfo.isIOS
            ? CupertinoIcons.home
            : Icons.home_outlined,
        selectedIcon: PlatformInfo.isIOS26OrHigher()
            ? "house.fill"
            : PlatformInfo.isIOS
            ? CupertinoIcons.home
            : Icons.home,
        label: 'Home',
      ),
      AdaptiveNavigationDestination(
        icon: PlatformInfo.isIOS26OrHigher()
            ? "person.fill"
            : PlatformInfo.isIOS
            ? CupertinoIcons.person
            : Icons.person_outline,
        selectedIcon: PlatformInfo.isIOS26OrHigher()
            ? "person.fill"
            : PlatformInfo.isIOS
            ? CupertinoIcons.person_fill
            : Icons.person,
        label: 'Profile',
      ),
      AdaptiveNavigationDestination(
        icon: PlatformInfo.isIOS26OrHigher()
            ? "magnifyingglass"
            : PlatformInfo.isIOS
            ? CupertinoIcons.search
            : Icons.search,
        label: 'Search',
        isSearch: true,
      ),
    ],
    // child is automatically wrapped into a single-item children list for iOS26Scaffold
    // The scaffold handles showing the content based on selectedIndex
    child: _buildPageForIndex(_selectedIndex),
  )
Press enter or click to view image in full size

Segmented Control — Native Multi-Choice Selector
Native segmented control component that provides iOS-style multi-choice selection with liquid glass effects. Perfect for switching between related options or filter controls.

Press enter or click to view image in full size

Flutter iOS 26 Liquid Glass Segmented Control
AdaptiveSegmentedControl(
  labels: const ['One', 'Two', 'Three'],
  selectedIndex: _basicSegmentedControlIndex,
  onValueChanged: (i) =>
      setState(() => _basicSegmentedControlIndex = i),
),

AdaptiveSegmentedControl(
  labels: const [],
  sfSymbols: const [
    'house.fill',
    'leaf.arrow.trianglehead.clockwise',
    'figure.walk.diamond',
  ],
  selectedIndex: _iconSegmentedControlIndex,
  iconColor: CupertinoColors.systemBlue,
  shrinkWrap: true,
  onValueChanged: (i) =>
      setState(() => _iconSegmentedControlIndex = i),
  height: 48,
),
Slider — Native Value Selector
Native slider component that provides iOS-style value selection with liquid glass effects and smooth animations. Perfect for adjusting settings, volume controls, or any continuous value input.

Press enter or click to view image in full size

Flutter iOS 26 Liquid Glass Slider
AdaptiveSlider(
  value: _rangeValue,
  min: 0,
  max: 100,
  onChanged: (value) => setState(() => _rangeValue = value),
  activeColor: Colors.purple,
),
Native switch component that provides iOS-style toggle functionality with liquid glass effects and smooth animations. Perfect for binary settings, feature toggles, and on/off controls.

Press enter or click to view image in full size

Flutter iOS 26 Liquid Glass Alert Switch
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text(switchValue ? 'ON' : 'OFF'),
    SizedBox(
      width: 20,
    ),
    AdaptiveSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
    ),
  ],
),
And of course, we can’t wrap this up without a huge shout-out to the adaptive_platform_ui package. The developers behind this library have done an incredible job bringing some of iOS’s coolest features directly to Flutter. Without their hard work, creating a realistic and fluid experience like this would be nearly impossible. So, as you use this package in your own projects, don’t forget to give the developers a small “thank you” or offer your support. Their motivation means better tools for all of us.

Hopefully, this guide has inspired you to go beyond the Liquid Glass effect and explore the many other possibilities that Flutter and native features offer. Happy coding!

To use the components, add the following lines to your pubspec.yaml file:

adaptive_platform_ui: ^0.1.6 #check the latest version
adaptive_platform_ui | Flutter package
Adaptive platform-specific widgets for Flutter. Automatically renders native iOS 26+ designs, traditional Cupertino…
pub.dev