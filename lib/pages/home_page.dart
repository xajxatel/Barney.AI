import 'dart:io';
import 'dart:typed_data';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Gemini gemini = Gemini.instance;

  List<ChatMessage> messages = [];
  bool showBarneyImage = true;

  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Barney",
    profileImage: "assets/images/barney.png",
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.ralewayTextTheme(
          Theme.of(context).textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF388E3C)), // Dark green
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80.0), // Increase the height here
          child: GestureDetector(
            onTap: _resetChat,
            child: AppBar(
              backgroundColor: Color(0xFF388E3C),
              centerTitle: true,
              title: Column(
                children: [
                  SizedBox(height: 25,),
                  Text(
                    "Barney Stinson",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: GoogleFonts.raleway().fontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            _buildUI(),
            if (showBarneyImage)
              Positioned(
                top: 40, // Adjust the top position to move the image a bit above the center
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/barney.png',
                      height: 200,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Barney Stinson',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),
                    const Text(
                      'Lifestyle Blogger',
                      style: TextStyle(fontSize: 17),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'www.barneystinsonblog.com',
                      style: TextStyle(fontSize: 17),
                    ),
                     const SizedBox(height: 5),
                    const Text(
                      '202 East 67th Street, New York, NY',
                      style: TextStyle(fontSize: 17),
                    ),
                    
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUI() {
    return DashChat(
      inputOptions: InputOptions(trailing: [
        IconButton(
          onPressed: _sendMediaMessage,
          icon: const Icon(Icons.image),
        )
      ]),
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
      messageOptions: const MessageOptions(
        currentUserContainerColor: Color(0xFF388E3C), // Dark green for current user's messages
        currentUserTextColor: Colors.white,
        containerColor: Color.fromARGB(255, 231, 255, 232), // Light green for other user's messages
        textColor: Colors.black,
      ),
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
      showBarneyImage = false; // Hide Barney's image after the first message
    });
    try {
      String question = _createBarneyPrompt(chatMessage.text);
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [File(chatMessage.medias!.first.url).readAsBytesSync()];
      }
      gemini
          .streamGenerateContent(question, images: images)
          .listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        if (lastMessage != null && lastMessage.user == geminiUser) {
          lastMessage = messages.removeAt(0);
          String response = event.content?.parts?.fold(
                  "", (previous, current) => "$previous ${current.text}") ??
              "";
          lastMessage.text += response;
          setState(() {
            messages = [lastMessage!, ...messages];
          });
        } else {
          String response = event.content?.parts?.fold(
                  "", (previous, current) => "$previous ${current.text}") ??
              "";
          ChatMessage message = ChatMessage(
            user: geminiUser,
            createdAt: DateTime.now(),
            text: response,
          );
          setState(() {
            messages = [message, ...messages];
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  String _createBarneyPrompt(String userMessage) {
    return '''
Points to Remember before any further questions - 1.) Talk like Barney Stinson , Use as much catchphrases and keep the information fun and short , when youre asked about your identity , answer youre barney himself 2.) use as much catchphrases and keep the info light and not to detailed 3.) Avoid Boring questions by talking about your life 4.) Whenever youre explaining or answering to a user's question ofter divert from the topic to talk about something else or your private life 5.) Talk about your friends ted , marshall ,lily ,robin ocassionaly in coversations 6.) Speak like an American not like an Englishman 7.) I also wanted you to know youre a part of an AI mobile application that uses OpenAI's API to generate request designed by Raj Patel , a Student at BITS Pilani Hyderabad Campus 8.) if you're asked to create/generate an image/art , just say 'select the second option of the main screen
Barney is known for his brash, manipulative and opinionated personality. He is a womanizer known for his love of expensive suits, laser tag, and Scotch whisky. The character uses many 'plays' in his 'playbook' to help him have sex with women. In later seasons, he has a few serious relationships, then marries, divorces, and has a child with an unnamed woman from a one-night stand, and then marries the same woman again (as implied in the alternate ending). Barney's catchphrases included "Suit up!", “Go for Barney”, "What up?!", "Stinson out", "Legendary", "Wait for it" (often combining the two as "legen—wait for it—dary!"), "Daddy's home", "Haaaaave you met Ted", “True story”, “That’s the dream!”, "Challenge accepted", and "I only have one rule." (that one rule is constantly changing).
User: $userMessage

Barney Stinson: ''';
  }

  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Describe this picture?",
        medias: [
          ChatMedia(
            url: file.path,
            fileName: "",
            type: MediaType.image,
          )
        ],
      );
      _sendMessage(chatMessage);
    }
  }

  void _resetChat() {
    setState(() {
      messages.clear();
      showBarneyImage = true;
    });
  }
}
