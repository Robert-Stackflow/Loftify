import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Product-level icon semantics. Pages should use these names instead of
/// importing an icon font directly.
///
/// Names describe product meaning, never visual variants such as `filled`,
/// `outlined`, `active` or `selected`. A persistent state keeps the same glyph
/// and is expressed by the shared icon component. A different glyph is only
/// valid when the action itself changes, for example play/pause.
abstract final class LoftifyIcons {
  static const IconData home = LucideIcons.compass;
  static const IconData search = LucideIcons.search;
  static const IconData activity = LucideIcons.heart;
  static const IconData profile = LucideIcons.userRound;
  static const IconData logout = LucideIcons.logOut;
  static const IconData dress = LucideIcons.shirt;
  static const IconData notifications = LucideIcons.bell;
  static const IconData settings = LucideIcons.settings;
  static const IconData flag = LucideIcons.flag;
  static const IconData copyright = LucideIcons.copyright;
  static const IconData block = LucideIcons.ban;
  static const IconData tag = LucideIcons.tag;
  static const IconData shield = LucideIcons.shield;
  static const IconData previous = LucideIcons.chevronLeft;
  static const IconData next = LucideIcons.chevronRight;
  static const IconData previousPost = LucideIcons.chevronsLeft;
  static const IconData nextPost = LucideIcons.chevronsRight;
  static const IconData expand = LucideIcons.chevronDown;
  static const IconData sortDirection = LucideIcons.arrowDownUp;
  static const IconData favorite = LucideIcons.heart;
  static const IconData recommend = LucideIcons.thumbsUp;
  static const IconData hot = LucideIcons.flame;
  static const IconData egg = LucideIcons.egg;
  static const IconData magic = LucideIcons.wandSparkles;
  static const IconData select = LucideIcons.circle;
  static const IconData more = LucideIcons.ellipsis;
  static const IconData moreVertical = LucideIcons.ellipsisVertical;
  static const IconData slide = LucideIcons.chevronsRight;
  static const IconData edit = LucideIcons.pencil;
  static const IconData history = LucideIcons.history;
  static const IconData premium = LucideIcons.crown;
  static const IconData shop = LucideIcons.shoppingBag;
  static const IconData avatarFrame = LucideIcons.frame;
  static const IconData copy = LucideIcons.copy;
  static const IconData follow = LucideIcons.userPlus;
  static const IconData specialFollow = LucideIcons.star;
  static const IconData unfollow = LucideIcons.userMinus;
  static const IconData bookmark = LucideIcons.bookmark;
  static const IconData comment = LucideIcons.messageCircle;
  static const IconData article = LucideIcons.scrollText;
  static const IconData invalidContent = LucideIcons.circleAlert;
  static const IconData originalPost = LucideIcons.fileText;
  static const IconData quote = LucideIcons.quote;
  static const IconData reblog = LucideIcons.repeat2;
  static const IconData collection = LucideIcons.libraryBig;
  static const IconData grain = LucideIcons.wheat;
  static const IconData filter = LucideIcons.listFilter;
  static const IconData listLayout = LucideIcons.layoutList;
  static const IconData gridLayout = LucideIcons.layoutGrid;
  static const IconData scrollTop = LucideIcons.arrowUp;
  static const IconData trendUp = LucideIcons.trendingUp;
  static const IconData trendDown = LucideIcons.trendingDown;

  static const IconData refresh = LucideIcons.refreshCw;
  static const IconData save = LucideIcons.save;
  static const IconData add = LucideIcons.plus;
  static const IconData check = LucideIcons.check;
  static const IconData warning = LucideIcons.triangleAlert;
  static const IconData clear = LucideIcons.x;
  static const IconData visible = LucideIcons.eye;
  static const IconData hidden = LucideIcons.eyeOff;
  static const IconData reset = LucideIcons.rotateCcw;
  static const IconData openExternal = LucideIcons.externalLink;

  static const IconData merge = LucideIcons.gitMerge;
  static const IconData bug = LucideIcons.bug;
  static const IconData commit = LucideIcons.gitCommitHorizontal;
  static const IconData review = LucideIcons.messageSquareText;
  static const IconData share = LucideIcons.share2;
  static const IconData support = LucideIcons.circleHelp;
  static const IconData contact = LucideIcons.atSign;
  static const IconData language = LucideIcons.languages;
  static const IconData group = LucideIcons.users;
  static const IconData send = LucideIcons.send;
  static const IconData phone = LucideIcons.smartphone;
  static const IconData verification = LucideIcons.shieldCheck;
  static const IconData password = LucideIcons.keyRound;
  static const IconData lofterId = LucideIcons.idCard;
  static const IconData email = LucideIcons.mail;

  static const IconData generalSettings = LucideIcons.settings2;
  static const IconData appearance = LucideIcons.paintbrushVertical;
  static const IconData image = LucideIcons.image;
  static const IconData basicSettings = settings;
  static const IconData experiment = LucideIcons.flaskConical;
  static const IconData info = LucideIcons.info;
  static const IconData about = info;

  static const IconData download = LucideIcons.download;
  static const IconData batchDownload = LucideIcons.folderDown;
  static const IconData file = LucideIcons.file;
  static const IconData video = LucideIcons.video;
  static const IconData pause = LucideIcons.pause;
  static const IconData play = LucideIcons.play;
  static const IconData retry = LucideIcons.rotateCcw;
  static const IconData close = LucideIcons.x;
  static const IconData delete = LucideIcons.trash2;
}
