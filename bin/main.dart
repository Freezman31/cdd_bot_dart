import 'package:args/args.dart';
import 'package:nyxx/nyxx.dart';

void main(List<String> arguments) {
  var parser = ArgParser()
    ..addOption('token', abbr: 't', help: 'The token of your bot', defaultsTo: 'null')
    ..addOption('ordersChannelId', abbr: 'c', help: 'The id of the channel of the orders', defaultsTo: 'null')
    ..addFlag('help', negatable: true, abbr: 'h');

  var results = parser.parse(arguments);

  if(results.arguments.contains('--help') || results.arguments.contains('-n')){
    print(parser.usage);
    return;
  }
  if(results['token'] == 'null' || results['ordersChannelId'] == 'null'){
    print(parser.usage);
    return;
  }

  var bot = Nyxx(results['token'],
      GatewayIntents.all);
  var commandTemp = {};
  var commanders = {};

  bot.onDmReceived.listen((event) async {
    if (event.message.author.bot) return;
    for (var s in commanders.entries) {
      String value = s.value;

      var step = int.parse(value.split(',')[1]);
      var user = value.split(',')[0];
      var userInst = await bot.httpEndpoints.fetchUser(Snowflake(user));
      var username = userInst.username;
      var content = event.message.content;
      if (event.message.author.username == user) continue;
      print('continued');
      switch (step) {
        case 0:
          commandTemp.putIfAbsent(s.key, () => '*$content');
          var embed1 = EmbedBuilder()
            ..title = 'Votre assistant de commande'
            ..fields.add(EmbedFieldBuilder('Description',
                'Afin de vous faire comprendre, veuillez ajouter une description claire  à votre commande, qui explique le but, et qui peut contenir votre cahier des charges'));
          step++;
          commanders.update(s.key, (value) => '$user,$step');
          await event.message.channel.sendMessage(MessageBuilder.embed(embed1));
          break;
        case 1:
          var previous = commandTemp.entries.elementAt(s.key);
          commandTemp.update(s.key, (value) => '$previous*$content');
          var embed1 = EmbedBuilder()
            ..title = 'Votre assistant de commande'
            ..fields.add(EmbedFieldBuilder('Domaine',
                'Vous devez rentrer ici le type de programme que vous voulez ou son language'));
          step++;
          commanders.update(s.key, (value) => '$user,$step');
          await event.message.channel.sendMessage(MessageBuilder.embed(embed1));
          break;
        case 2:
          var previous = commandTemp.entries.elementAt(s.key);
          commandTemp.update(s.key, (value) => '$previous*$content');
          var embed1 = EmbedBuilder()
            ..title = 'Votre assistant de commande'
            ..fields.add(EmbedFieldBuilder('Prix/Budget',
                'Veuillez entrer ici votre budget **MAXIMUM**, les comandes gratuites sont interdites '));
          step++;
          commanders.update(s.key, (value) => '$user,$step');
          await event.message.channel.sendMessage(MessageBuilder.embed(embed1));
          break;
        case 3:
          var previous = commandTemp.entries.elementAt(s.key);
          commandTemp.update(s.key, (value) => '$previous*$content');
          var embed1 = EmbedBuilder()
            ..title = 'Votre assistant de commande'
            ..fields.add(EmbedFieldBuilder('Validation',
                'Veuillez envoyer \'send\' pour valider votre commande'));
          step++;
          commanders.update(s.key, (value) => '$user,$step');
          await event.message.channel.sendMessage(MessageBuilder.embed(embed1));
          break;
        case 4:
          if (content.toLowerCase() == 'send') {
            String commandTempContent =
                commandTemp.entries.elementAt(s.key).value;
            print(commandTempContent);
            await event.message.channel.sendMessage(
                MessageBuilder.content('Votre commande va être envoyé !'));
            var commandContent = commandTempContent.split('*');
            print(commandContent.length);
            print(commandTempContent);
            print(commandContent);
            var channel = await bot.httpEndpoints
                .fetchChannel(Snowflake(results['ordersChannelId']));
            print(commandContent.length);
            channel.sendMessage(MessageBuilder.embed(EmbedBuilder()
              ..title = 'Commande de $username'
              ..color = DiscordColor.blurple
              ..fields.addAll({
                EmbedFieldBuilder(
                    'Titre', commandContent.elementAt(1).replaceAll(')', '')),
                EmbedFieldBuilder('Description',
                    commandContent.elementAt(2).replaceAll(')', '')),
                EmbedFieldBuilder(
                    'Domaine', commandContent.elementAt(3).replaceAll(')', '')),
                EmbedFieldBuilder(
                    'Budget',
                    '**' +
                        commandContent.elementAt(4).replaceAll(')', '') +
                        '**')
              })));
            step = 0;
            commandContent.remove(s.key);
            commanders.remove(s.key);
          }
      }
    }
  });

  bot.onMessageReactionAdded.listen((event) async {
    await event.user.download();
    bot.users.add(event.user.id, await event.user.download());
    var chan = await event.user.getFromCache()!.dmChannel;
    var user = chan.participant;

    var embed = EmbedBuilder()
      ..title = 'Votre assistant de commande'
      ..description =
          'Je suis votre assistant de commande, je vais vous aider à faire votre commande :thumbsup:'
      ..fields.add(EmbedFieldBuilder(
          'Un nom', 'Veuillez donner un nom à votre annonce !'));

    commanders.putIfAbsent(commanders.length, () => '$user,0');

    await chan.sendMessage(MessageBuilder.embed(embed));
  });
}
