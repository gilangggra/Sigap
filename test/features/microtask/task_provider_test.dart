import 'package:flutter_test/flutter_test.dart';
import 'package:sigap/features/microtask/domain/models/task_item.dart';
import 'package:sigap/features/microtask/presentation/state/task_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TaskProvider Mutual-Aid Tests', () {
    late TaskProvider provider;

    setUp(() {
      provider = TaskProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('Inisialisasi awal provider tidak dalam kondisi loading', () {
      expect(provider.isLoading, isFalse);
      expect(provider.nearbyTasks, isEmpty);
      expect(provider.myClaimedTasks, isEmpty);
      expect(provider.selectedCategory, isNull);
    });

    test('loadNearbyTasks mengisi daftar tugas bantuan di sekitar', () async {
      await provider.loadNearbyTasks();

      expect(provider.nearbyTasks, isNotEmpty);
      expect(provider.nearbyTasks.length, greaterThanOrEqualTo(2));
    });

    test('setCategoryFilter menyaring tugas berdasarkan kategori', () async {
      await provider.loadNearbyTasks();
      final initialCount = provider.nearbyTasks.length;

      provider.setCategoryFilter(TaskCategory.ambilResep);
      for (final task in provider.nearbyTasks) {
        expect(task.category, equals(TaskCategory.ambilResep));
      }

      provider.setCategoryFilter(null);
      expect(provider.nearbyTasks.length, equals(initialCount));
    });

    test('acceptTask memindahkan tugas ke daftar myClaimedTasks', () async {
      await provider.loadNearbyTasks();
      final targetTask = provider.nearbyTasks.first;

      final success = await provider.acceptTask(
        taskId: targetTask.id,
        responderId: 'resp-test-01',
        responderName: 'Relawan Uji Coba',
      );

      expect(success, isTrue);
      expect(provider.myClaimedTasks, isNotEmpty);
      expect(provider.myClaimedTasks.first.id, equals(targetTask.id));
      expect(provider.myClaimedTasks.first.status, equals(TaskStatus.accepted));
    });
  });
}

