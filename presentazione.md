# Speech per la presentazione - Lumi: A Journey Through Fairy Tales

Lingua dello speech: inglese, per coerenza con le slide e con le note relatore della Keynote.

Durata target: circa 18-21 minuti, includendo passaggi tra speaker, piccole pause e video/demo. Se serve arrivare piu vicino a 15 minuti, tagliare prima il business model e qualche esempio tecnico, non la parte accessibility.

Nota deck: le slide 43-50 sembrano materiale poster/appendix/backup. Lo speech principale copre slide 1-42.

## Divisione tra i 7 speaker

1. Marcello Guida - Intro, team, contesto sociale e tecnologico - slide 1-5 - circa 2 min.
2. Albi Karameta - Temporal sequences, Borgione, fondamento cognitivo - slide 10-16 - circa 2.5 min.
3. Adolfo Torcicollo - Target, ricerca utenti, scelta delle fiabe - slide 17-24 - circa 2.5 min.
4. Giulia Chiappetta - Interviste, desirability, user testing - slide 27, 31-32 - circa 2 min.
5. Bobur Toshpulatov - Prodotto finale e demo flow - slide 29-30 - circa 2.5 min.
6. Ciro Calisto - Tecnologie, architettura, localizzazione - slide 33-35 - circa 2 min.
7. Francesca De Marco - Accessibility dettagliata, business model, conclusione - slide 36-42 - circa 5-6 min.

---

## 1. Marcello Guida - Introduction and context

Good morning everyone. We are Genesis, and today we are presenting our project: Lumi, A Journey Through Fairy Tales.

I am Marcello Guida, and with me are Albi Karameta, Adolfo Torcicollo, Bobur Toshpulatov, Ciro Calisto, Giulia Chiappetta, and Francesca De Marco. Each of us worked on a different part of the project: research, product definition, interface design, development, testing, accessibility, and business analysis.

Before presenting the app itself, we want to explain the context in which the project was born.

Education today is changing rapidly. Children are growing up with digital tools, interactive media, games, and visual interfaces. This does not mean that traditional educational materials are no longer useful. Many of them are still extremely valuable. But technology allows us to rethink how these activities can be made more engaging, more adaptive, and more accessible.

One important social force is gamification. In learning environments, gamification can increase motivation because children are not just receiving information: they are acting, making decisions, receiving feedback, and progressing step by step.

At the same time, digital devices offer opportunities that physical materials cannot always provide: animation, audio support, personalization, multilingual content, accessibility settings, and immediate feedback.

So our starting question was simple: how can we use technology to create a meaningful educational experience for children?

We did not want to build only a game, and we did not want to build a static educational exercise. We wanted to combine the engagement of play with a real learning objective. That objective became the understanding of temporal sequences.

I now pass the presentation to Albi, who will explain why temporal sequences became the core of our project.

---

## 2. Albi Karameta - Temporal sequences and educational inspiration

Thank you, Marcello.

The central learning concept behind Lumi is temporal sequencing: understanding what happens first, what happens after, and why the order of events matters.

This is a fundamental cognitive skill. Children use temporal sequencing to understand stories, daily routines, instructions, cause and effect, and problem solving. When a child understands that one action makes another action possible, they are not simply memorizing. They are building logical thinking.

During our research, we looked for existing educational activities that already support this skill. We found "Laboratorio delle Sequenze" by Borgione, a physical board game based on visual cards. Children look at different scenes and place them in chronological order.

What inspired us was the simplicity of this activity. The child does not need complex rules. They observe, compare, remember, and arrange. But even if the interaction is simple, the learning value is strong: it trains attention, semantic memory, visual memory, logical reasoning, and problem solving.

At that point, we asked ourselves: what if we could bring this experience into a digital environment?

Our goal was not to replace the physical activity, but to expand it. A digital version can add animated transitions, immediate feedback, progressive levels, sound, haptics, and accessibility options. It can also create a stronger sense of journey, because children are not completing isolated exercises; they are moving through a story world.

We also found research support for this direction. Fivush and Mandler explain that children often sequence events by relying on their world knowledge. Familiar events in forward order are easier to reconstruct. This means that, if children already understand the context, they can focus more clearly on the order and logic of the events.

This insight changed our design. Instead of asking children to sequence random images, we decided to use familiar narratives. The activity becomes more than "put four cards in order." It becomes: understand the story, recognize relationships between actions, and rebuild the narrative step by step.

Now Adolfo will explain how we defined our target and why fairy tales became the right context.

---

## 3. Adolfo Torcicollo - Target users and fairy tales

Thank you, Albi.

After defining the learning activity, we needed to understand who could benefit from it the most.

At the beginning, we considered children with autism as a possible target group. This was a meaningful direction because visual sequences, routines, predictable structures, and clear steps can be useful in many neurodivergent learning contexts.

However, during research, we realized that the specific skill addressed by our game - ordering familiar events in a temporal sequence - was not necessarily the primary learning need for the first target we had imagined. This was important, because it helped us avoid forcing the product toward a target that did not fully match the learning objective.

So we refined our audience and focused on children in primary school, especially children around 4 to 8 years old. At this age, children are developing story comprehension, chronological thinking, attention, and visual memory. They are also often asked to retell stories, organize events, and distinguish before, after, and finally.

Then we made another key decision: we chose fairy tales.

Fairy tales are powerful because they are familiar. Many children already know stories like Little Red Riding Hood, or they can learn them easily through reading and listening. This familiarity reduces cognitive effort. The child does not need to understand a completely new world from zero; they can focus on the order of events.

For example, in Little Red Riding Hood, a child can understand that first the mother prepares the basket, then Little Red Riding Hood walks into the forest, then she meets the wolf, then the wolf arrives at grandmother's house. The story makes sense because each event creates the conditions for the next one.

Fairy tales also have emotional value. They include characters, places, danger, surprise, and resolution. This makes the learning experience more engaging. The child is not just solving a puzzle; they are helping a story become whole again.

This is how our concept became Lumi: a journey through fairy tales where children restore the correct order of story events.

Giulia will now explain how we validated this direction with interviews and user testing.

---

## 4. Giulia Chiappetta - Validation, interviews, and desirability

Thank you, Adolfo.

Once we had a clearer concept, we moved into validation. We wanted to understand whether the idea made sense not only in theory, but also for real users and real educational contexts.

We gathered feedback through interviews, including parents and perspectives connected to autism support. These conversations helped us confirm three important needs.

First, the experience has to be simple. Children should understand what to do without long explanations. The interface must be visual, direct, and consistent.

Second, feedback must be gentle. Lumi should not punish mistakes. If a child places the cards in the wrong order, the app should encourage them to try again. The goal is learning through repetition and confidence, not pressure.

Third, the content must feel meaningful. Parents are more likely to value an educational app when the learning objective is clear. In Lumi, that objective is story comprehension, chronological thinking, attention, and visual memory.

We also observed children interacting with the prototype. This helped us understand if they recognized the task, if the cards were clear, and if the story world kept them interested.

The feedback confirmed the value of familiar narratives and showed that the map, characters, sequencing activity, rewards, and storybook create stronger motivation than a simple exercise screen.

Another important insight was that Lumi can support both independent play and co-learning. A child can play alone, but a parent, teacher, or therapist can also sit next to them and discuss the sequence of events.

Now Bobur will show what Lumi actually is and how the experience works.

---

## 5. Bobur Toshpulatov - Product experience and app flow

Thank you, Giulia.

The final result is Lumi: A Journey Through Fairy Tales, a gamified educational app that helps children understand temporal sequences through stories they already know.

The app is structured as a journey. Children enter a colorful world map, where each island can represent a fairy tale. In the current prototype, the complete story is Little Red Riding Hood, while the structure is ready to expand to other stories in the future.

The main character, Lumi, moves through the map and helps restore stories whose events have been mixed up. This gives the child a clear mission: help Lumi put the fairy tale back in the correct order.

In Little Red Riding Hood, the child moves through a dedicated story map divided into chapters. Each chapter represents one narrative moment: preparing the basket, walking in the forest, meeting the wolf, arriving at grandmother's house, and so on.

Each chapter follows a clear flow.

First, there is a short introduction, so the child understands the context.

Second, there is the sequencing activity. The child receives four illustrated cards in a mixed order and must arrange them from left to right in the correct chronological sequence.

Third, there is feedback and reward. If the answer is correct, the child receives positive feedback and unlocks the next chapter. If the answer is wrong, the child can try again without losing progress.

As chapters are completed, a storybook is progressively unlocked. This is important because the child sees the result of learning: they are not only completing levels, they are rebuilding a book.

The prototype also includes an optional augmented reality storybook mode, where unlocked story cards can be visualized in the physical environment. This connects digital storytelling with the real world and opens space for future expansion.

So Lumi is not only a card-ordering exercise. It is a complete experience built around exploration, narrative, feedback, progression, and learning.

Now Ciro will explain the technologies behind the app.

---

## 6. Ciro Calisto - Technologies and implementation

Thank you, Bobur.

From a technical perspective, Lumi was developed as an iOS and iPadOS application using SwiftUI.

SwiftUI allowed us to build a highly visual and adaptive interface with reusable components, animations, and state-driven views. This was important because the app needs to work across different devices, especially iPad and iPhone.

We used Combine and observable state to manage changes such as language, progress, settings, and interface updates. User progress and preferences are saved locally with UserDefaults, including completed levels, unlocked chapters, selected language, audio settings, animation preferences, haptics, and accessibility options.

The story content is data-driven. Events, cards, correct order, intro text, reward text, and dialogue can be loaded from structured data. This makes the project scalable: future fairy tales can follow the same structure without redesigning the whole app.

For audio, we used AVFoundation. The app includes background music, ambience, sound effects, and speech synthesis. Audio supports engagement, feedback, and accessibility.

For augmented reality, we used ARKit and SceneKit. ARKit manages camera-based world tracking, while SceneKit renders story cards in 3D space.

The app also supports localization in English, Italian, Albanian, and Russian. This makes the experience more inclusive for families with different language backgrounds.

Finally, the typography system supports both the default playful font and OpenDyslexic, which can be activated through accessibility settings.

Now Francesca will go deeper into one of the most important parts of the project: accessibility.

---

## 7. Francesca De Marco - Accessibility, business model, and conclusion

Thank you, Ciro.

Accessibility was not treated as something to add at the end. For us, accessibility is part of the product concept. Lumi is an educational app for children, and if a children's educational app is not accessible, it risks excluding exactly the users who may need support the most.

We approached accessibility from multiple perspectives: visual accessibility, screen reader support, motor accessibility, sensory accessibility, cognitive accessibility, language accessibility, and privacy.

First, visual accessibility.

The app supports Dynamic Type through fonts connected to system text styles. This means text can scale according to user preferences instead of staying fixed. We also integrated OpenDyslexic. When the dyslexia font option is enabled, the typography system switches globally from the default font to a dyslexia-friendly font, making the interface easier to read for children with reading difficulties.

Contrast was also considered carefully. In our accessibility documentation, we use WCAG AA as a reference, especially the 4.5:1 contrast target for normal text and 3:1 for large text and UI components. This is important because Lumi is visually rich, but the fairy-tale style cannot reduce readability. Buttons, story text, settings, and cards must remain clear.

Second, screen reader and voice support.

The app includes accessibility labels and hints for many interactive elements: play, settings, info, back buttons, storybook, map locations, sequence cards, dialogue panels, and chapter unlocks. This means VoiceOver can announce the purpose of an element instead of reading only an icon or an image.

Complex elements are grouped when needed, so VoiceOver reads them as meaningful units. Decorative images can be hidden, so they do not create unnecessary noise. This is especially important in a storybook interface full of illustrations, frames, clouds, icons, and characters.

The app also includes speech synthesis through AVSpeechSynthesizer. Dialogue and storybook pages can be read aloud in the selected language. The speech rate is slightly slower to be more child-friendly, and when narration starts, the background music is lowered so the voice stays understandable. This helps younger children who cannot read independently and also supports users who prefer listening.

Third, motor accessibility.

Children need large, forgiving controls. The app follows Apple Human Interface Guidelines with a minimum touch target of 44 by 44 points, and many main controls are larger, especially on iPad. The play button, map controls, storybook button, settings rows, and circular buttons are designed to be easy to tap.

The sequencing activity also avoids making the learning goal depend only on precise movement. Dragging cards is natural, but the app supports readable card descriptions and clear slots. The important challenge should be understanding the sequence, not struggling with the gesture.

Fourth, sensory accessibility.

The app includes settings for music, sound effects, and haptics. Sound and vibration can make the experience more engaging, but for some children they can also be overwhelming. In Lumi, feedback is never only sound-based. The child also receives visual feedback, text, rewards, unlocked chapters, and story progression.

We also support reduced motion. Animation-heavy components check the system Reduce Motion setting and the app's own reduce animation preference. When reduced motion is active, transitions become simpler and more stable. This applies to effects such as cloud transitions, typewriter text, panels, and rewards.

Fifth, cognitive accessibility.

This is one of the strongest parts of the project. We chose familiar fairy tales because they reduce cognitive load. Children do not need to learn a completely new story world before solving the sequence. They can rely on memory, context, and visual clues.

The structure is predictable: introduction, sequencing activity, feedback, reward, unlock. This repetition helps children understand what is expected and supports users who benefit from routine.

Mistakes are handled gently. There is no punishment and no pressure. The child can retry, receive encouragement, and continue learning. This keeps the activity emotionally safe.

We also avoid using color as the only indicator of meaning. A locked or completed chapter should not be communicated only through grey or green. It also needs icons, labels, checkmarks, shapes, or text feedback. This supports color-blind users and makes the interface clearer for children.

Sixth, language accessibility and privacy.

Lumi supports English, Italian, Albanian, and Russian, so families can use the app in a language closer to them. Also, the app does not require registration or login. It does not use tracking, advertising, analytics, or user profiling. Progress and preferences stay locally on the device. The AR feature uses the camera locally through ARKit and does not record or upload camera data.

So when we say Lumi is accessible, we mean that the experience is readable, listenable, touchable, predictable, adjustable, multilingual, and privacy-conscious.

Moving to the business model, Lumi is designed for children aged 4 to 8, while parents and educators are the decision makers. The value proposition is to transform familiar stories into interactive learning experiences that develop chronological thinking, story comprehension, attention, and visual memory.

The long-term model can be freemium: one fairy tale available for free, and additional fairy tales or story packs available as premium content. This keeps the entry point accessible while creating a sustainable way to maintain and expand the app.

To conclude, every story has meaning because its events happen in the right order. With Lumi, we help children discover this idea through fairy tales they already know and love.

This project combines educational research, storytelling, game design, accessibility, and technology. It starts from a simple activity - putting events in order - and transforms it into a journey where children can learn by playing.

Thank you for listening.

---

## Passaggi rapidi tra speaker

Marcello to Albi: "I now pass the presentation to Albi, who will explain why temporal sequences became the core of our project."

Albi to Adolfo: "Now Adolfo will explain how we defined our target and why fairy tales became the right context."

Adolfo to Giulia: "Giulia will now explain how we validated this direction with interviews and user testing."

Giulia to Bobur: "Now Bobur will show what Lumi actually is and how the experience works."

Bobur to Ciro: "Now Ciro will explain the technologies behind the app."

Ciro to Francesca: "Now Francesca will go deeper into one of the most important parts of the project: accessibility."

## Note per la prova orale

Durante i video o la demo, introdurre con una frase breve, lasciare vedere l'interazione e poi riprendere spiegando cosa il pubblico ha appena visto.

Nella parte accessibility, parlare lentamente e separare bene i blocchi: visual accessibility, VoiceOver, motor accessibility, sensory accessibility, cognitive accessibility, language accessibility e privacy.

Se il tempo e troppo stretto, tagliare qualche frase del business model. Non tagliare VoiceOver, Dynamic Type, reduced motion, touch targets e cognitive accessibility.
