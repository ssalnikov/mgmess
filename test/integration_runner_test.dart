// Runner для запуска integration-сценариев как обычных widget-тестов.
// Позволяет запускать без устройства: flutter test test/integration_runner_test.dart
//
// Для полного E2E на устройстве используйте:
//   flutter test integration_test/scenarios/ -d <device_id>

import '../integration_test/scenarios/auth_flow_test.dart' as auth_flow;
import '../integration_test/scenarios/channel_list_test.dart' as channel_list;
import '../integration_test/scenarios/send_message_test.dart' as send_message;
import '../integration_test/scenarios/receive_message_ws_test.dart'
    as receive_ws;
import '../integration_test/scenarios/pin_unpin_test.dart' as pin_unpin;
import '../integration_test/scenarios/search_channels_test.dart'
    as search_channels;
import '../integration_test/scenarios/thread_navigation_test.dart'
    as thread_nav;
import '../integration_test/scenarios/edit_delete_message_test.dart'
    as edit_delete;
import '../integration_test/scenarios/unread_counter_test.dart'
    as unread_counter;
import '../integration_test/scenarios/channel_grouping_test.dart'
    as channel_grouping;
import '../integration_test/scenarios/custom_status_test.dart'
    as custom_status;

void main() {
  auth_flow.main();
  channel_list.main();
  send_message.main();
  receive_ws.main();
  pin_unpin.main();
  search_channels.main();
  thread_nav.main();
  edit_delete.main();
  unread_counter.main();
  channel_grouping.main();
  custom_status.main();
}
