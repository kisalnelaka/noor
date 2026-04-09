import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/websocket_service.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:ui';

class DocumentViewer extends StatefulWidget {
  final String localPath;
  final String title;
  final int highlightPage;
  final WebSocketService? wsService;

  const DocumentViewer({
    Key? key,
    required this.localPath,
    required this.title,
    this.highlightPage = 0,
    this.wsService,
  }) : super(key: key);

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  final Completer<PDFViewController> _controller = Completer<PDFViewController>();
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: Text(widget.title.toUpperCase(), style: const TextStyle(fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
              centerTitle: true,
              backgroundColor: Colors.white.withOpacity(0.05),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          PDFView(
            filePath: widget.localPath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            defaultPage: widget.highlightPage,
            onRender: (_pages) {
              setState(() { pages = _pages; isReady = true; });
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _controller.complete(pdfViewController);
            },
            onPageChanged: (int? page, int? total) {
              setState(() { currentPage = page; });
            },
          ),
          
          if (!isReady)
            const Center(child: CircularProgressIndicator(color: AuraTheme.accentBlue)),
            
          Positioned(
            bottom: 30, right: 30,
            child: FloatingActionButton.extended(
              backgroundColor: AuraTheme.accentBlue,
              icon: const Icon(Icons.psychology_rounded, color: Colors.white),
              label: const Text("EXPLAIN THIS SECTION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () {
                if (widget.wsService != null) {
                  widget.wsService!.sendMessage(jsonEncode({
                    "type": "document_query",
                    "content": "Explain page ${currentPage! + 1} of this lease document for ${widget.title}",
                    "document": widget.title
                  }));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("NOOR is analyzing this clause...")),
                  );
                  Navigator.pop(context); // Close PDF to see the AI response in chat
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
