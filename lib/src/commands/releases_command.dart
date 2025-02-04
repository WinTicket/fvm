import 'package:args/command_runner.dart';
import 'package:dart_console/dart_console.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/services/releases_service/models/release.model.dart';
import 'package:fvm/src/utils/console_utils.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:mason_logger/mason_logger.dart';

import '../services/releases_service/releases_client.dart';
import 'base_command.dart';

/// List installed SDK Versions
class ReleasesCommand extends BaseCommand {
  @override
  final name = 'releases';

  @override
  final description = 'View all Flutter SDK releases available for install.';

  /// Constructor
  // Add option to pass channel name
  ReleasesCommand() {
    argParser.addOption(
      'channel',
      help: 'Filter by channel name',
      abbr: 'c',
      allowed: ['stable', 'beta', 'dev', 'all'],
      defaultsTo: 'stable',
    );
  }

  @override
  Future<int> run() async {
    // Get channel name
    final channelName = stringArg('channel');
    final allChannel = 'all';

    if (channelName != null) {
      if (!isFlutterChannel(channelName) && channelName != allChannel) {
        throw UsageException('Invalid Channel name: $channelName', usage);
      }
    }

    bool shouldFilterRelease(Release release) {
      if (channelName == allChannel) {
        return false;
      }
      return release.channel.name != channelName;
    }

    logger.detail('Filtering by channel: $channelName');

    final releases = await FlutterReleases.get();

    final versions = releases.releases.reversed;

    final table = createTable()
      ..insertColumn(header: 'Version', alignment: TextAlignment.left)
      ..insertColumn(header: 'Release Date', alignment: TextAlignment.left)
      ..insertColumn(header: 'Channel', alignment: TextAlignment.left);

    for (var release in versions) {
      var channelLabel = release.channel.toString().split('.').last;
      if (release.activeChannel) {
        // Add checkmark icon
        // as ascii code
        // Add backgroundColor
        final checkmark = String.fromCharCode(0x2713);

        channelLabel = '$channelLabel ${green.wrap(checkmark)}';
      }

      if (shouldFilterRelease(release)) {
        continue;
      }

      table.insertRow([
        release.version,
        friendlyDate(release.releaseDate),
        channelLabel,
      ]);
    }

    logger.info(table.toString());

    logger.info('Channel:');

    final channelsTable = createTable()
      ..insertColumn(header: 'Channel', alignment: TextAlignment.left)
      ..insertColumn(header: 'Version', alignment: TextAlignment.left)
      ..insertColumn(header: 'Release Date', alignment: TextAlignment.left);

    for (var release in releases.channels.toList) {
      if (shouldFilterRelease(release)) {
        continue;
      }
      channelsTable.insertRow([
        release.channel.name,
        release.version,
        friendlyDate(release.releaseDate)
      ]);
    }

    logger.info(channelsTable.toString());

    return ExitCode.success.code;
  }
}
