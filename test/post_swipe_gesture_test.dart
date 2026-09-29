import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Utils/post_swipe_gesture.dart';

void main() {
  test('commit distance stays usable on narrow and wide layouts', () {
    expect(PostSwipeGesturePolicy.commitDistance(240), 72);
    expect(PostSwipeGesturePolicy.commitDistance(400), 88);
    expect(PostSwipeGesturePolicy.commitDistance(1200), 128);
    expect(
      PostSwipeGesturePolicy.hasReachedCommitDistance(
        rawOffset: 87.9,
        viewportWidth: 400,
      ),
      isFalse,
    );
    expect(
      PostSwipeGesturePolicy.hasReachedCommitDistance(
        rawOffset: -88,
        viewportWidth: 400,
      ),
      isTrue,
    );
  });

  test('a deliberate drag commits only when the direction is available', () {
    expect(
      PostSwipeGesturePolicy.shouldCommit(
        rawOffset: -88,
        velocity: -100,
        viewportWidth: 400,
        available: true,
      ),
      isTrue,
    );
    expect(
      PostSwipeGesturePolicy.shouldCommit(
        rawOffset: -120,
        velocity: -100,
        viewportWidth: 400,
        available: false,
      ),
      isFalse,
    );
  });

  test('a fling needs minimum travel and matching velocity direction', () {
    expect(
      PostSwipeGesturePolicy.shouldCommit(
        rawOffset: 40,
        velocity: 1000,
        viewportWidth: 400,
        available: true,
      ),
      isTrue,
    );
    expect(
      PostSwipeGesturePolicy.shouldCommit(
        rawOffset: 30,
        velocity: 1200,
        viewportWidth: 400,
        available: true,
      ),
      isFalse,
    );
    expect(
      PostSwipeGesturePolicy.shouldCommit(
        rawOffset: 40,
        velocity: -1200,
        viewportWidth: 400,
        available: true,
      ),
      isFalse,
    );
  });

  test('first and last boundaries apply resistance instead of switching', () {
    expect(
      PostSwipeGesturePolicy.visualOffset(
        rawOffset: 100,
        viewportWidth: 400,
        available: false,
      ),
      closeTo(22, 0.001),
    );
    expect(
      PostSwipeGesturePolicy.visualOffset(
        rawOffset: -100,
        viewportWidth: 400,
        available: false,
      ),
      closeTo(-22, 0.001),
    );
  });

  test('edge hint appears only after a deliberate pull', () {
    expect(PostSwipeGesturePolicy.hintRevealProgress(30), 0);
    expect(PostSwipeGesturePolicy.hintRevealProgress(44), 0);
    expect(PostSwipeGesturePolicy.hintRevealProgress(66), closeTo(0.5, 0.001));
    expect(PostSwipeGesturePolicy.hintRevealProgress(88), 1);
    expect(PostSwipeGesturePolicy.hintRevealProgress(-120), 1);
  });

  test('first and last hints share the normal commit threshold', () {
    expect(
      PostSwipeGesturePolicy.boundaryHintRevealProgress(
        rawOffset: 87.9,
        viewportWidth: 400,
        hasSequenceContext: true,
      ),
      0,
    );
    expect(
      PostSwipeGesturePolicy.boundaryHintRevealProgress(
        rawOffset: 88,
        viewportWidth: 400,
        hasSequenceContext: true,
      ),
      1,
    );
    expect(
      PostSwipeGesturePolicy.boundaryHintRevealProgress(
        rawOffset: 120,
        viewportWidth: 400,
        hasSequenceContext: false,
      ),
      0,
    );
  });
}
