import 'package:flutter_test/flutter_test.dart';
import 'package:dailies/data/habit_store.dart';
import 'package:dailies/models/habit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save then load roundtrips habits', () async {
    final store = HabitStore();
    final habits = [
      Habit(
        id: 'a',
        name: 'Read',
        iconIndex: 2,
        colorIndex: 3,
        doneDates: {'2026-10-19'},
      ),
      Habit(
        id: 'b',
        name: 'Stretch',
        iconIndex: 0,
      ),
    ];

    await store.save(habits);
    final loaded = await store.load();

    expect(loaded, hasLength(2));
    expect(loaded.first.name, 'Read');
    expect(loaded.first.doneDates, {'2026-10-19'});
    expect(loaded.last.name, 'Stretch');
  });

  test('load returns empty list when nothing is stored', () async {
    expect(await HabitStore().load(), isEmpty);
  });

  test('load recovers from corrupt payload', () async {
    SharedPreferences.setMockInitialValues({
      'dailies.habits.v1': '{not valid json[',
    });
    expect(await HabitStore().load(), isEmpty);
  });
}
