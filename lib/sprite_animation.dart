import 'package:meta/meta.dart';
import 'dart:ui';

import 'extensions/vector2.dart';
import 'sprite.dart';

class SpriteAnimationOpts {
  int amount;
  int amountPerRow;
  Vector2 texturePosition;
  Vector2 textureSize;
  List<double> stepTimes;
  bool loop;

  SpriteAnimationOpts({
    @required this.amount,
    @required this.stepTimes,
    this.amountPerRow,
    this.texturePosition,
    this.textureSize,
    this.loop = true,
  });

  SpriteAnimationOpts.sequenced({
    @required int amount,
    int amountPerRow,
    Vector2 texturePosition,
    Vector2 textureSize,
    bool loop = true,
    double stepTime = 0.1,
  }) : this(
          amount: amount,
          amountPerRow: amountPerRow,
          texturePosition: texturePosition,
          textureSize: textureSize,
          loop: loop,
          stepTimes: List.filled(amount, stepTime),
        );
}

/// Represents a single sprite animation frame.
class SpriteAnimationFrame {
  /// The [Sprite] to be displayed.
  Sprite sprite;

  /// The duration to display it, in seconds.
  double stepTime;

  /// Create based on the parameters.
  SpriteAnimationFrame(this.sprite, this.stepTime);
}

typedef OnCompleteSpriteAnimation = void Function();

/// Represents a sprite animation, that is, a list of sprites that change with time.
class SpriteAnimation {
  /// The frames that compose this animation.
  List<SpriteAnimationFrame> frames = [];

  /// Index of the current frame that should be displayed.
  int currentIndex = 0;

  /// Current clock time (total time) of this animation, in seconds, since last frame.
  ///
  /// It's ticked by the update method. It's reset every frame change.
  double clock = 0.0;

  /// Total elapsed time of this animation, in seconds, since start or a reset.
  double elapsed = 0.0;

  /// Whether the animation loops after the last sprite of the list, going back to the first, or keeps returning the last when done.
  bool loop = true;

  /// Registered method to be triggered when the animation complete.
  OnCompleteSpriteAnimation onComplete;

  /// Creates an animation given a list of frames.
  SpriteAnimation(this.frames, {this.loop = true});

  /// Creates an empty animation
  SpriteAnimation.empty();

  /// Creates an animation based on the parameters.
  ///
  /// All frames have the same [stepTime].
  SpriteAnimation.spriteList(
    List<Sprite> sprites, {
    @required double stepTime,
    this.loop = true,
  }) : assert(stepTime != null) {
    if (sprites.isEmpty) {
      throw Exception('You must have at least one frame!');
    }
    frames = sprites.map((s) => SpriteAnimationFrame(s, stepTime)).toList();
  }

  /// Creates an SpriteAnimation based on its [opts]
  SpriteAnimation.fromImage(
    Image image,
    SpriteAnimationOpts opts,
  )   : assert(opts != null),
        assert(opts.amountPerRow == null || opts.amount >= opts.amountPerRow),
        assert(opts.stepTimes != null),
        assert(image != null) {
    opts.amountPerRow ??= opts.amount;
    opts.texturePosition ??= Vector2.zero();
    frames = List<SpriteAnimationFrame>(opts.amount);
    for (int i = 0; i < opts.amount; i++) {
      final position = Vector2(
        opts.texturePosition.x + (i % opts.amountPerRow) * opts.textureSize.x,
        opts.texturePosition.y + (i ~/ opts.amountPerRow) * opts.textureSize.y,
      );
      final Sprite sprite = Sprite(
        image,
        SpriteOpts(
          srcPosition: position,
          srcSize: opts.textureSize,
        ),
      );
      frames[i] = SpriteAnimationFrame(sprite, opts.stepTimes[i]);
    }
  }

  /// Automatically creates an Animation Object using animation data provided by the json file
  /// provided by Aseprite
  ///
  /// [imagePath]: Source of the sprite sheet animation
  /// [dataPath]: Animation's exported data in json format
  SpriteAnimation.fromAsepriteData(
    Image image,
    Map<String, dynamic> jsonData,
  ) {
    final jsonFrames = jsonData['frames'] as Map<String, Map<String, dynamic>>;

    final frames = jsonFrames.values.map((value) {
      final frameData = value['frame'] as Map<String, dynamic>;
      final int x = frameData['x'] as int;
      final int y = frameData['y'] as int;
      final int width = frameData['w'] as int;
      final int height = frameData['h'] as int;

      final stepTime = (value['duration'] as int) / 1000;

      final Sprite sprite = Sprite(
        image,
        SpriteOpts(
          srcPosition: Vector2Extension.fromInts(x, y),
          srcSize: Vector2Extension.fromInts(width, height),
        ),
      );

      return SpriteAnimationFrame(sprite, stepTime);
    });

    this.frames = frames.toList();
    loop = true;
  }

  /// The current frame that should be displayed.
  SpriteAnimationFrame get currentFrame => frames[currentIndex];

  /// Returns whether the animation is on the last frame.
  bool get isLastFrame => currentIndex == frames.length - 1;

  /// Returns whether the animation has only a single frame (and is, thus, a still image).
  bool get isSingleFrame => frames.length == 1;

  /// Sets a different step time to each frame. The sizes of the arrays must match.
  set variableStepTimes(List<double> stepTimes) {
    assert(stepTimes.length == frames.length);
    for (int i = 0; i < frames.length; i++) {
      frames[i].stepTime = stepTimes[i];
    }
  }

  /// Sets a fixed step time to all frames.
  set stepTime(double stepTime) {
    frames.forEach((frame) => frame.stepTime = stepTime);
  }

  /// Resets the animation, like it would just have been created.
  void reset() {
    clock = 0.0;
    elapsed = 0.0;
    currentIndex = 0;
  }

  /// Gets the current [Sprite] that should be shown.
  ///
  /// In case it reaches the end:
  ///  * If [loop] is true, it will return the last sprite. Otherwise, it will go back to the first.
  Sprite getSprite() {
    return currentFrame.sprite;
  }

  /// If [loop] is false, returns whether the animation is done (fixed in the last Sprite).
  ///
  /// Always returns false otherwise.
  bool done() {
    return loop ? false : (isLastFrame && clock >= currentFrame.stepTime);
  }

  /// Updates this animation, ticking the lifeTime by an amount [dt] (in seconds).
  void update(double dt) {
    clock += dt;
    elapsed += dt;
    if (isSingleFrame) {
      return;
    }
    if (!loop && isLastFrame) {
      onComplete?.call();
      return;
    }
    while (clock > currentFrame.stepTime) {
      if (!isLastFrame) {
        clock -= currentFrame.stepTime;
        currentIndex++;
      } else if (loop) {
        clock -= currentFrame.stepTime;
        currentIndex = 0;
      } else {
        break;
      }
    }
  }

  /// Returns a new Animation based on this animation, but with its frames in reversed order
  SpriteAnimation reversed() {
    return SpriteAnimation(frames.reversed.toList(), loop: loop);
  }

  /// Computes the total duration of this animation (before it's done or repeats).
  double totalDuration() {
    return frames.map((f) => f.stepTime).reduce((a, b) => a + b);
  }
}
