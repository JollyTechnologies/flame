# Game Loop

The Game Loop module is a simple abstraction over the game loop concept. Basically most games are built upon two methods:

* The render method takes the canvas ready for drawing the current state of the game.
* The update method receives the delta time in seconds since last update and allows you to move to the next state.

The class `Game` can be subclassed and will provide, among others, these gameloop methods.
At the same time, a `Game` subclass instance can be added to a Flutter widget tree via the `GameWidget`.

You can add it into the topo of you tree (directly as an argument to `runApp`) or inside the usual app-like widget structure widget structure (with scaffold, routes and whatnot).

Example of usage directly into `runApp`:

```dart
    main() {
        runApp(
          GameWidget(
            game: MyGameSubClass()
          )
        );
    }
```

It is important to notice that `Game` is an abstract class with just the very basic implementations of the gameloop.

As an option and more suitable for most cases, there is the full-featured `BaseGame` class. For advanced the Forge2D physics engine use `Forge2DGame` class;

The `BaseGame` implements a `Component` based `Game` for you; basically it has a list of `Component`s and passes the `update` and `render` calls appropriately. You can still extend those methods to add custom behavior, and you will get a few other features for free, like the passing of `resize` methods (every time the screen is resized the information will be passed to the resize methods of all your components) and also a basic camera feature. The `BaseGame.camera` controls which point in coordinate space should be the top-left of the screen (defaults to [0,0] like a regular `Canvas`).

A very simple `BaseGame` implementation example can be seen below:

```dart
    class MyCrate extends SpriteComponent {

        // creates a component that renders the crate.png sprite, with size 16 x 16
        MyCrate() : super.fromSprite(16.0, 16.0, new Sprite('crate.png'));

        @override
        void onGameResize(Size size) {
            // we don't need to set the x and y in the constructor, we can set then here
            this.x = (size.width - this.width)/ 2;
            this.y = (size.height - this.height) / 2;
        }
    }

    class MyGame extends BaseGame {
        MyGame() {
            add(new MyCrate()); // this will call resize the first time as well
        }
    }
```

To remove components from the list on a `BaseGame` the `markToRemove` method can be used.

## Flutter Widgets and Game instances

Since a Flame game can be considered a widget itself, it is quite easy to use it alongside Flutter widgets. But there is a the Widgets overlay API that makes things even easier.

Flame provides a `mixin` called `HasWidgetsOverlay` which will enable any Flutter widget to be show on top of your game instance, this makes it very easy to create things like a pause menu, or an inventory screen for example.

To use it, simple add the `HasWidgetsOverlay` `mixin` on your game class, by doing so, the game class will have a `.overlays` property that will be used to manage the active overlays.  
This management happens via the `.overlays.add` and `.overlays.remove` methods that marks a overlay to be shown and hidden, respectively, via a `String` argument that identifies a overlay.  
After that, it can be specified which widgets represents each overlay, in the `GameWidget` declaration using the `GameWidget.withOverlay` constructor.

```dart
// inside game methods:

final pauseOverlayIdentifier = "PauseMenu";
overlays.add(pauseOverlayIdentifier); // marks "PauseMenu" to be renderable.
overlays.remove(pauseOverlayIdentifier); // marks "PauseMenu" to not be renderable.
```

```dart
// on the widget declaration

return GameWidget.withOverlay(
  game: MyGameSubClass() // MyGameSubClass has to be mixed with `HasWidgetsOverlay` 
  overlayBuilderMap: {
    "PauseMenu": (context) { // notice the overlay identifier
      return Positioned.fill( // Overlays are rendered directly under a stack, so Positioned are eligible
        child: Text("This is a pause menu")
      );
    },
  },
)
```

The order in which the overlays are declared on the `overlayBuilderMap` defines which overlay will be rendered first.

Here you can see a [working example](/doc/examples/with_widgets_overlay) of this feature.

## BaseGame debug mode

Flame's `BaseGame` class provides a method called `debugMode`, which by default returns false. It can however, be overridden to enable debug features over the components of the game. __Be aware__ that the state returned by this method is passed through its component when they added to the game, so if you change the `debugMode` in runtime, it may not affect already added components.

To see more about debugMode on Flame, please refer to the [Debug Docs](/doc/debug.md)

