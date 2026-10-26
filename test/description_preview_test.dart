import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/features/tasks/presentation/description_preview.dart';

void main() {
  group('descriptionPreview', () {
    test('a single line is shown unchanged', () {
      expect(descriptionPreview('Suchleiste'), 'Suchleiste');
    });

    test('more lines add an ellipsis to the first one', () {
      expect(descriptionPreview('Suchleiste\nFilter\nSortierung'), 'Suchleiste…');
    });

    test('Windows line breaks count as line breaks', () {
      expect(descriptionPreview('Suchleiste\r\nFilter'), 'Suchleiste…');
    });

    test('blank lines are skipped', () {
      expect(descriptionPreview('\n  Suchleiste  \n\n'), 'Suchleiste');
      expect(descriptionPreview('\nSuchleiste\n\nFilter'), 'Suchleiste…');
    });

    test('only whitespace gives an empty preview', () {
      expect(descriptionPreview(' \n \n'), '');
    });
  });
}
