import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gameshare/services/database_actions.dart';
import 'package:gameshare/view/components/reviewForm/review_form.dart';
import 'package:gameshare/view/components/utils/add_vertical_space.dart';
import 'package:gameshare/view/components/utils/left_centered_title.dart';
import '../../model/game.dart';
import '../../model/review.dart';
import '../../services/api_requests.dart';
import '../../services/providers/scroll_provider.dart';
import '../components/circular_progress.dart';
import '../components/game_card.dart';
import '../components/game_page/image_with_text.dart';
import '../components/nav_bar.dart';
import '../components/review_card.dart';
import '../components/text_section.dart';
import '../components/top_bar.dart';

class GamePage extends StatefulWidget {
  const GamePage({
    super.key,
    required this.game,
  });
  final Game game;

  @override
  State<StatefulWidget> createState() => _GamePage(game: game);
}

class _GamePage extends State<GamePage> {
  _GamePage({
    required this.game,
  });

  final Game game;
  bool loadingOtherReviews = true;
  bool loadingMyReview = true;
  bool didntFetchData = true;
  List<Review> otherReviews = [];
  Review? myReview;

  setOtherReviews(List<Review> reviews) {
    setState(() {
      otherReviews = reviews;
      loadingOtherReviews = false;
    });
  }

  setMyReview(Review? review) {
    setState(() {
      myReview = review;
      loadingMyReview = false;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  Widget getReviewsWidget() {
    if (loadingOtherReviews) {
      return const CircularProgressBar();
    } else {
      return Column(
        children: createReviewCards(otherReviews),
      );
    }
  }

  Widget getMyReviewWidget() {
    if (loadingMyReview) {
      return const CircularProgressBar();
    } else {
      if (myReview == null) {
        return ReviewForm(game: game);
      } else {
        return Column(
          children: [
            const addVerticalSpace(size: 10),
            ReviewCard(
              name: FirebaseAuth.instance.currentUser!.email!,
              review: myReview!.reviewText,
              rating: myReview!.rating,
            ),
          ],
        );
      }
    }
  }

  List<Widget> createReviewCards(List<Review> reviews) {
    List<Widget> reviewCards = [];

    for (Review review in reviews) {
      reviewCards.add(ReviewCard(
        name: review.userEmail,
        review: review.reviewText,
        rating: review.rating,
      ));
    }

    return reviewCards;
  }

  @override
  Widget build(BuildContext context) {
    if (didntFetchData) {
      didntFetchData = false;
      getGameReviews(game.gameId).then((reviews) => {setOtherReviews(reviews)});

      if (FirebaseAuth.instance.currentUser != null) {
        getUserGameReview(
          FirebaseAuth.instance.currentUser!.email!, game.gameId)
            .then((review) => {setMyReview(review)});
      }
    }
    Future<String> description = getGameDescription(game.gameId);

    return Scaffold(
      appBar: const TopBar(),
      body: Stack(
        children: [
          ListView(
            controller: ScrollProvider.scrollController,
            children: [
              ImageWithText(
                imageUrl: game.image,
                title: game.name,
              ),
              plataformRating(game: game),
              FutureBuilder<String>(
                future: description,
                builder: (context, AsyncSnapshot<String> snapshot) {
                  if (snapshot.hasData) {
                    return TextSection(
                        title: "About",
                        text: snapshot.data ??
                            "There is no Information about this game");
                  } else {
                    return const CircularProgressBar();
                  }
                },
              ),
              const addVerticalSpace(size: 30),
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: LeftCenteredTitle(text: "Reviews", textSize: 32),
              ),
              const addVerticalSpace(size: 10),
              if (FirebaseAuth.instance.currentUser != null)
                getMyReviewWidget(),
              const addVerticalSpace(size: 10),
              getReviewsWidget(),
            ],
          ),
          const GoBackButton(),
        ],
      ),
      bottomNavigationBar: const NavBar(),
    );
  }
}

class GoBackButton extends StatelessWidget {
  const GoBackButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.pop(context);
      },
      style: ButtonStyle(
        padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(0)),
      ),
      child: Icon(
        Icons.arrow_circle_left,
        size: 40,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}

class plataformRating extends StatelessWidget {
  const plataformRating({
    super.key,
    required this.game,
  });
  final Game game;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: EdgeInsets.only(left: 10, right: 10, top: 15, bottom: 10),
        child: Row(
          children: [
            SizedBox(
              width: 10,
              height: 0,
            ),
            for (int i = 0; i < 3 && i < game.uniquePlatformsIcons.length; i++)
              SizedBox(
                  height: 40,
                  width: 50,
                  child: Icon(
                    game.uniquePlatformsIcons[i],
                    size: 35,
                  )),
            const SizedBox(width: 5),
            if (game.uniquePlatformsIcons.length > 3)
              MorePlatformsNumber(game: game),
            GameCardRating(game: game, size: 50),
            SizedBox(
              width: 10,
              height: 0,
            ),
          ],
        ),
      ),
    );
  }
}
