/**
 * Seed content for the numbers 1-9 in English, Hindi and Marathi.
 *
 * This is the baseline content shipped with the product. Every field is
 * editable from the admin panel - the app reads this content from the database,
 * never from source code.
 */

export type SeedLocale = 'en' | 'hi' | 'mr';

export interface NumberCopy {
  name: string;
  title: string;
  summary: string;
  personality: string;
  behaviour: string;
  strengths: string[];
  weaknesses: string[];
  career: string;
  relationships: string;
  general: string;
  colors: string[];
  notes: string;
}

export interface NumberSeed {
  number: number;
  luckyNumbers: number[];
  unfavourableNumbers: number[];
  copy: Record<SeedLocale, NumberCopy>;
}

export const NUMBER_SEEDS: NumberSeed[] = [
  {
    number: 1,
    luckyNumbers: [1, 2, 3, 9],
    unfavourableNumbers: [8],
    copy: {
      en: {
        name: 'The Leader',
        title: 'Number 1 - Sun',
        summary: 'Number 1 is traditionally associated with the Sun: leadership, independence and the confidence to start something new.',
        personality:
          'People with number 1 usually like to lead rather than follow. They think independently, make decisions quickly and prefer to be responsible for their own results. Numerology suggests a natural pull towards responsibility, and a dislike of being controlled by others.',
        behaviour:
          'You take initiative early, speak directly and expect the same clarity from others. When a plan is yours, you will work very hard for it. When it is forced on you, your interest drops quickly.',
        strengths: ['Leadership', 'Confidence', 'Independence', 'Clear decision making', 'Willpower', 'Original thinking'],
        weaknesses: ['Ego', 'Stubbornness', 'Impatience with slower people', 'Difficulty accepting advice', 'Can appear dominating'],
        career:
          'Traditionally associated with business ownership, senior management, government service, administration, defence, engineering and any work where you set the direction. Roles with no authority usually feel restrictive.',
        relationships:
          'You are loyal and protective, but you need respect and personal space. Relationships work best with partners who appreciate your drive instead of competing with it. Learning to listen without correcting helps a great deal.',
        general:
          'Numerology suggests that number 1 does best when it has a clear goal of its own. Progress is usually steady rather than sudden, and early responsibility is common.',
        colors: ['Golden yellow', 'Orange', 'Deep red'],
        notes: 'Ruling planet: Sun (Surya). Traditionally linked with Sunday.',
      },
      hi: {
        name: 'नेतृत्वकर्ता',
        title: 'अंक 1 - सूर्य',
        summary: 'अंक 1 परंपरागत रूप से सूर्य से जुड़ा है: नेतृत्व, स्वतंत्रता और कुछ नया शुरू करने का आत्मविश्वास।',
        personality:
          'अंक 1 वाले लोग आमतौर पर किसी के पीछे चलने के बजाय आगे बढ़कर नेतृत्व करना पसंद करते हैं। वे स्वतंत्र रूप से सोचते हैं, निर्णय जल्दी लेते हैं और अपने परिणामों की जिम्मेदारी स्वयं लेना चाहते हैं। अंक ज्योतिष के अनुसार इन्हें जिम्मेदारी स्वाभाविक रूप से आकर्षित करती है और दूसरों का नियंत्रण पसंद नहीं आता।',
        behaviour:
          'आप पहल जल्दी करते हैं, सीधी बात करते हैं और दूसरों से भी वैसी ही स्पष्टता की उम्मीद रखते हैं। जो योजना आपकी अपनी होती है, उसके लिए आप बहुत मेहनत करते हैं; थोपी हुई योजना में आपकी रुचि जल्दी कम हो जाती है।',
        strengths: ['नेतृत्व क्षमता', 'आत्मविश्वास', 'स्वतंत्रता', 'स्पष्ट निर्णय', 'इच्छाशक्ति', 'मौलिक सोच'],
        weaknesses: ['अहंकार', 'जिद', 'धीमे लोगों के प्रति अधीरता', 'सलाह स्वीकार करने में कठिनाई', 'कभी-कभी दबदबा दिखाना'],
        career:
          'परंपरागत रूप से व्यवसाय, वरिष्ठ प्रबंधन, सरकारी सेवा, प्रशासन, रक्षा, इंजीनियरिंग और ऐसे हर काम से जुड़ा है जहाँ दिशा आप तय करते हैं। बिना अधिकार वाली भूमिकाएँ आमतौर पर बंधन जैसी लगती हैं।',
        relationships:
          'आप वफादार और रक्षा करने वाले होते हैं, लेकिन आपको सम्मान और अपनी जगह चाहिए। ऐसे साथी के साथ संबंध अच्छे चलते हैं जो आपकी लगन की कद्र करे, उससे प्रतिस्पर्धा न करे। बिना टोके सुनना सीखना बहुत मदद करता है।',
        general:
          'अंक ज्योतिष बताती है कि अंक 1 तब सबसे अच्छा करता है जब उसका अपना स्पष्ट लक्ष्य हो। प्रगति आमतौर पर अचानक नहीं, स्थिर रूप से होती है और जिम्मेदारी जल्दी आती है।',
        colors: ['सुनहरा पीला', 'नारंगी', 'गहरा लाल'],
        notes: 'स्वामी ग्रह: सूर्य। परंपरागत रूप से रविवार से संबंधित।',
      },
      mr: {
        name: 'नेतृत्व करणारा',
        title: 'अंक 1 - सूर्य',
        summary: 'अंक 1 पारंपरिकपणे सूर्याशी जोडलेला आहे: नेतृत्व, स्वातंत्र्य आणि नवीन काही सुरू करण्याचा आत्मविश्वास.',
        personality:
          'अंक 1 असलेल्या व्यक्ती सहसा दुसऱ्यामागे जाण्यापेक्षा पुढे राहून नेतृत्व करणे पसंत करतात. ते स्वतंत्रपणे विचार करतात, निर्णय लवकर घेतात आणि स्वतःच्या निकालाची जबाबदारी स्वतः घेतात. अंकशास्त्रानुसार त्यांना जबाबदारी नैसर्गिकपणे आकर्षित करते आणि दुसऱ्याचे नियंत्रण आवडत नाही.',
        behaviour:
          'तुम्ही पुढाकार लवकर घेता, स्पष्ट बोलता आणि इतरांकडूनही तशाच स्पष्टतेची अपेक्षा ठेवता. जी योजना तुमची स्वतःची असते तिच्यासाठी तुम्ही खूप मेहनत करता; लादलेल्या योजनेत रस लवकर कमी होतो.',
        strengths: ['नेतृत्वगुण', 'आत्मविश्वास', 'स्वातंत्र्य', 'स्पष्ट निर्णय', 'इच्छाशक्ती', 'मूळ विचार'],
        weaknesses: ['अहंकार', 'हट्टीपणा', 'संथ लोकांबद्दल अधीरता', 'सल्ला स्वीकारण्यात अडचण', 'कधी कधी वर्चस्व गाजवणे'],
        career:
          'पारंपरिकपणे स्वतःचा व्यवसाय, वरिष्ठ व्यवस्थापन, सरकारी सेवा, प्रशासन, संरक्षण, अभियांत्रिकी आणि जिथे दिशा तुम्ही ठरवता अशा कामाशी संबंधित. अधिकार नसलेल्या भूमिका सहसा बंधनकारक वाटतात.',
        relationships:
          'तुम्ही निष्ठावान आणि संरक्षण करणारे असता, पण तुम्हाला आदर आणि स्वतःची मोकळीक लागते. तुमच्या जिद्दीची कदर करणारा जोडीदार असेल तर नाते चांगले चालते. मध्येच न थांबवता ऐकायला शिकणे खूप उपयोगी ठरते.',
        general:
          'अंकशास्त्र सुचवते की अंक 1 ला स्वतःचे स्पष्ट ध्येय असेल तेव्हा तो सर्वोत्तम काम करतो. प्रगती सहसा अचानक नव्हे तर स्थिरपणे होते आणि जबाबदारी लवकर येते.',
        colors: ['सोनेरी पिवळा', 'केशरी', 'गडद लाल'],
        notes: 'स्वामी ग्रह: सूर्य. पारंपरिकपणे रविवारशी संबंधित.',
      },
    },
  },
  {
    number: 2,
    luckyNumbers: [1, 2, 5, 7],
    unfavourableNumbers: [8, 9],
    copy: {
      en: {
        name: 'The Nurturer',
        title: 'Number 2 - Moon',
        summary: 'Number 2 is traditionally associated with the Moon: sensitivity, imagination and the ability to understand what others are feeling.',
        personality:
          'People with number 2 read a room quickly. They prefer harmony to argument, think about a decision from several sides, and often carry a strong imaginative or creative streak. Numerology suggests emotions guide them more than logic alone.',
        behaviour:
          'You adjust easily, avoid direct conflict and often play the peacemaker in a family or a team. Your mood can change with your surroundings, so a calm environment matters more to you than to most people.',
        strengths: ['Empathy', 'Diplomacy', 'Imagination', 'Team work', 'Patience', 'Attention to people'],
        weaknesses: ['Over-thinking', 'Mood swings', 'Difficulty saying no', 'Sensitivity to criticism', 'Indecision'],
        career:
          'Traditionally associated with teaching, counselling, healthcare, human resources, hospitality, design, music, writing and partnership businesses. Highly aggressive sales environments usually drain you.',
        relationships:
          'You are caring, romantic and deeply loyal. You need reassurance and gentle communication. Partners who are blunt without meaning harm can hurt you unintentionally, so speaking about feelings early prevents distance.',
        general:
          'Numerology suggests that number 2 does best in partnership rather than isolation. Rest, water, moonlight and quiet time are traditionally recommended for restoring balance.',
        colors: ['White', 'Cream', 'Silver', 'Light green'],
        notes: 'Ruling planet: Moon (Chandra). Traditionally linked with Monday.',
      },
      hi: {
        name: 'सहयोगी और भावुक',
        title: 'अंक 2 - चंद्रमा',
        summary: 'अंक 2 परंपरागत रूप से चंद्रमा से जुड़ा है: संवेदनशीलता, कल्पनाशीलता और दूसरों की भावनाएँ समझने की क्षमता।',
        personality:
          'अंक 2 वाले लोग माहौल को जल्दी भाँप लेते हैं। वे विवाद के बजाय सामंजस्य पसंद करते हैं, किसी निर्णय को कई पहलुओं से देखते हैं और अक्सर कल्पनाशील या रचनात्मक होते हैं। अंक ज्योतिष के अनुसार इन्हें केवल तर्क नहीं, भावनाएँ भी दिशा देती हैं।',
        behaviour:
          'आप आसानी से तालमेल बिठाते हैं, सीधे टकराव से बचते हैं और परिवार या टीम में अक्सर शांति बनाए रखने वाले होते हैं। आपका मन माहौल के साथ बदलता है, इसलिए शांत वातावरण आपके लिए दूसरों से ज्यादा मायने रखता है।',
        strengths: ['सहानुभूति', 'कूटनीति', 'कल्पनाशक्ति', 'टीम भावना', 'धैर्य', 'लोगों की समझ'],
        weaknesses: ['ज्यादा सोचना', 'मन का बदलना', 'मना करने में कठिनाई', 'आलोचना से जल्दी दुखी होना', 'निर्णय में देरी'],
        career:
          'परंपरागत रूप से शिक्षण, परामर्श, स्वास्थ्य सेवा, मानव संसाधन, आतिथ्य, डिज़ाइन, संगीत, लेखन और साझेदारी वाले व्यवसाय से जुड़ा है। अत्यधिक आक्रामक बिक्री का माहौल आमतौर पर थका देता है।',
        relationships:
          'आप स्नेही, रोमांटिक और गहरे वफादार होते हैं। आपको आश्वासन और कोमल बातचीत चाहिए। जो साथी बिना बुरा सोचे भी कठोर बोलते हैं, वे अनजाने में आपको दुख पहुँचा सकते हैं; भावनाओं पर समय रहते बात करने से दूरी नहीं बनती।',
        general:
          'अंक ज्योतिष बताती है कि अंक 2 अकेलेपन से ज्यादा साझेदारी में अच्छा करता है। विश्राम, जल, चाँदनी और शांत समय संतुलन के लिए परंपरागत रूप से सुझाए जाते हैं।',
        colors: ['सफेद', 'क्रीम', 'चाँदी जैसा', 'हल्का हरा'],
        notes: 'स्वामी ग्रह: चंद्रमा। परंपरागत रूप से सोमवार से संबंधित।',
      },
      mr: {
        name: 'सहकार्य करणारा',
        title: 'अंक 2 - चंद्र',
        summary: 'अंक 2 पारंपरिकपणे चंद्राशी जोडलेला आहे: संवेदनशीलता, कल्पकता आणि इतरांच्या भावना समजून घेण्याची क्षमता.',
        personality:
          'अंक 2 असलेल्या व्यक्ती वातावरण लगेच ओळखतात. त्यांना वादापेक्षा सलोखा आवडतो, निर्णय अनेक बाजूंनी तपासतात आणि बहुतेक वेळा कल्पक किंवा कलात्मक असतात. अंकशास्त्रानुसार त्यांना केवळ तर्कच नव्हे तर भावनाही दिशा देतात.',
        behaviour:
          'तुम्ही सहज जुळवून घेता, थेट संघर्ष टाळता आणि कुटुंबात किंवा संघात अनेकदा शांतता राखणारे असता. तुमचा मूड वातावरणानुसार बदलतो, त्यामुळे शांत वातावरण तुमच्यासाठी इतरांपेक्षा जास्त महत्त्वाचे असते.',
        strengths: ['सहानुभूती', 'मुत्सद्दीपणा', 'कल्पकता', 'सांघिक वृत्ती', 'संयम', 'माणसे ओळखण्याची हातोटी'],
        weaknesses: ['अतिविचार', 'मनःस्थिती बदलणे', 'नकार देण्यात अडचण', 'टीकेने लवकर दुखावणे', 'निर्णय लांबवणे'],
        career:
          'पारंपरिकपणे शिक्षण, समुपदेशन, आरोग्यसेवा, मनुष्यबळ विभाग, आतिथ्य, डिझाईन, संगीत, लेखन आणि भागीदारीतील व्यवसायाशी संबंधित. अतिशय आक्रमक विक्रीचे वातावरण सहसा थकवते.',
        relationships:
          'तुम्ही प्रेमळ, रोमँटिक आणि खोलवर निष्ठावान असता. तुम्हाला आधाराचे शब्द आणि मृदू संवाद लागतो. वाईट हेतू नसतानाही स्पष्टवक्ता जोडीदार नकळत दुखावू शकतो; भावनांबद्दल वेळेत बोलल्यास अंतर पडत नाही.',
        general:
          'अंकशास्त्र सुचवते की अंक 2 एकटेपणापेक्षा भागीदारीत अधिक चांगले काम करतो. विश्रांती, पाणी, चांदणे आणि शांत वेळ संतुलनासाठी पारंपरिकपणे सुचवले जातात.',
        colors: ['पांढरा', 'क्रीम', 'चंदेरी', 'फिकट हिरवा'],
        notes: 'स्वामी ग्रह: चंद्र. पारंपरिकपणे सोमवारशी संबंधित.',
      },
    },
  },
  {
    number: 3,
    luckyNumbers: [3, 6, 9, 1],
    unfavourableNumbers: [4],
    copy: {
      en: {
        name: 'The Teacher',
        title: 'Number 3 - Jupiter',
        summary: 'Number 3 is traditionally associated with Jupiter: knowledge, guidance, optimism and the ability to explain things to others.',
        personality:
          'People with number 3 enjoy learning and sharing what they know. They are usually cheerful, expressive and respected for their advice. Numerology suggests a natural teaching quality, whether or not they teach for a living.',
        behaviour:
          'You speak well, take an interest in principles and traditions, and are comfortable guiding people. You dislike disorder and prefer that things be done properly rather than quickly.',
        strengths: ['Knowledge', 'Communication', 'Optimism', 'Discipline', 'Generosity with advice', 'Sense of ethics'],
        weaknesses: ['Over-advising', 'Judging others', 'Pride in being right', 'Impatience with careless work', 'Taking on too much'],
        career:
          'Traditionally associated with teaching, law, finance, banking, consulting, medicine, writing, publishing, religious or social guidance and training roles.',
        relationships:
          'You are dependable and take commitments seriously. You value a partner you can respect intellectually. Remember that a partner sometimes wants comfort rather than correction.',
        general:
          'Numerology suggests that number 3 grows through study, teaching and steady discipline. Recognition often comes with age and experience.',
        colors: ['Yellow', 'Saffron', 'Gold'],
        notes: 'Ruling planet: Jupiter (Guru / Brihaspati). Traditionally linked with Thursday.',
      },
      hi: {
        name: 'मार्गदर्शक',
        title: 'अंक 3 - गुरु (बृहस्पति)',
        summary: 'अंक 3 परंपरागत रूप से बृहस्पति से जुड़ा है: ज्ञान, मार्गदर्शन, आशावाद और बात समझाने की क्षमता।',
        personality:
          'अंक 3 वाले लोग सीखना और अपना ज्ञान बाँटना पसंद करते हैं। ये आमतौर पर प्रसन्नचित्त, अभिव्यक्तिशील और अपनी सलाह के लिए सम्मानित होते हैं। अंक ज्योतिष के अनुसार इनमें सिखाने का स्वाभाविक गुण होता है, चाहे यह इनका पेशा हो या न हो।',
        behaviour:
          'आप अच्छा बोलते हैं, सिद्धांतों और परंपराओं में रुचि रखते हैं और लोगों का मार्गदर्शन सहजता से करते हैं। अव्यवस्था आपको पसंद नहीं; जल्दी करने से ज्यादा सही करना आपके लिए महत्वपूर्ण है।',
        strengths: ['ज्ञान', 'संवाद कौशल', 'आशावाद', 'अनुशासन', 'सलाह देने में उदारता', 'नैतिकता'],
        weaknesses: ['जरूरत से ज्यादा सलाह देना', 'दूसरों को आँकना', 'सही होने का अभिमान', 'लापरवाही पर अधीरता', 'बहुत सारे काम हाथ में लेना'],
        career:
          'परंपरागत रूप से शिक्षण, कानून, वित्त, बैंकिंग, परामर्श, चिकित्सा, लेखन, प्रकाशन, धार्मिक या सामाजिक मार्गदर्शन और प्रशिक्षण से जुड़ा है।',
        relationships:
          'आप भरोसेमंद हैं और वचन को गंभीरता से लेते हैं। आपको ऐसा साथी पसंद आता है जिसका आप बौद्धिक सम्मान कर सकें। याद रखें कि कभी-कभी साथी को सुधार नहीं, सहारा चाहिए होता है।',
        general:
          'अंक ज्योतिष बताती है कि अंक 3 अध्ययन, शिक्षण और निरंतर अनुशासन से आगे बढ़ता है। पहचान अक्सर उम्र और अनुभव के साथ मिलती है।',
        colors: ['पीला', 'केसरिया', 'सुनहरा'],
        notes: 'स्वामी ग्रह: बृहस्पति। परंपरागत रूप से गुरुवार से संबंधित।',
      },
      mr: {
        name: 'मार्गदर्शक',
        title: 'अंक 3 - गुरु (बृहस्पती)',
        summary: 'अंक 3 पारंपरिकपणे गुरूशी जोडलेला आहे: ज्ञान, मार्गदर्शन, आशावाद आणि समजावून सांगण्याची क्षमता.',
        personality:
          'अंक 3 असलेल्या व्यक्तींना शिकायला आणि आपले ज्ञान वाटायला आवडते. ते सहसा आनंदी, अभिव्यक्तिशील असतात आणि त्यांच्या सल्ल्यासाठी त्यांचा आदर केला जातो. अंकशास्त्रानुसार त्यांच्यात शिकवण्याचा नैसर्गिक गुण असतो, तो व्यवसाय असो वा नसो.',
        behaviour:
          'तुम्ही चांगले बोलता, तत्त्वे आणि परंपरांमध्ये रस घेता आणि लोकांना सहजपणे मार्गदर्शन करता. अव्यवस्था तुम्हाला आवडत नाही; घाईपेक्षा नीट करणे तुम्हाला महत्त्वाचे वाटते.',
        strengths: ['ज्ञान', 'संवादकौशल्य', 'आशावाद', 'शिस्त', 'सल्ला देण्यातील उदारता', 'नीतिमत्ता'],
        weaknesses: ['गरजेपेक्षा जास्त सल्ला', 'इतरांना जोखणे', 'बरोबर असल्याचा अभिमान', 'निष्काळजीपणावर अधीरता', 'खूप कामे अंगावर घेणे'],
        career:
          'पारंपरिकपणे शिक्षण, कायदा, वित्त, बँकिंग, सल्लागार सेवा, वैद्यकीय क्षेत्र, लेखन, प्रकाशन, धार्मिक किंवा सामाजिक मार्गदर्शन आणि प्रशिक्षणाशी संबंधित.',
        relationships:
          'तुम्ही विश्वासार्ह असता आणि वचन गांभीर्याने घेता. ज्याचा बौद्धिक आदर करता येईल असा जोडीदार तुम्हाला आवडतो. लक्षात ठेवा, कधी कधी जोडीदाराला सुधारणा नको तर आधार हवा असतो.',
        general:
          'अंकशास्त्र सुचवते की अंक 3 अभ्यास, शिकवणे आणि सातत्यपूर्ण शिस्तीतून वाढतो. ओळख बहुधा वय आणि अनुभवासोबत मिळते.',
        colors: ['पिवळा', 'भगवा', 'सोनेरी'],
        notes: 'स्वामी ग्रह: गुरु. पारंपरिकपणे गुरुवारशी संबंधित.',
      },
    },
  },
  {
    number: 4,
    luckyNumbers: [1, 4, 5, 7],
    unfavourableNumbers: [3, 9],
    copy: {
      en: {
        name: 'The Unconventional Worker',
        title: 'Number 4 - Rahu',
        summary: 'Number 4 is traditionally associated with Rahu: practical intelligence, an unusual way of thinking and the willingness to question accepted rules.',
        personality:
          'People with number 4 rarely accept something just because everybody does it. They notice details others miss, work in their own systematic way and often reach the same result by a completely different route. Numerology suggests sudden changes are common in their life.',
        behaviour:
          'You are dependable in work but not always predictable in method. You dislike being told to follow a process you consider illogical, and you keep your real opinion private until you trust someone.',
        strengths: ['Practical mind', 'Original methods', 'Hard work', 'Honesty', 'Problem solving', 'Handling complexity'],
        weaknesses: ['Restlessness', 'Arguing with authority', 'Overthinking risks', 'Difficulty relaxing', 'Feeling misunderstood'],
        career:
          'Traditionally associated with technology, research, engineering, machinery, aviation, media, real estate, data work, logistics and any field that rewards unconventional problem solving.',
        relationships:
          'You are loyal but private. Partners sometimes feel you are holding something back when you are simply thinking. Sharing plans early, even unfinished ones, makes relationships much smoother.',
        general:
          'Numerology suggests that number 4 benefits from structure it chooses for itself: fixed routines, clear finances and steady sleep reduce the restlessness this number is traditionally associated with.',
        colors: ['Grey', 'Electric blue', 'Khaki'],
        notes: 'Ruling planet: Rahu. Traditionally linked with the second half of Saturday.',
      },
      hi: {
        name: 'व्यावहारिक और अलग सोच वाला',
        title: 'अंक 4 - राहु',
        summary: 'अंक 4 परंपरागत रूप से राहु से जुड़ा है: व्यावहारिक बुद्धि, अलग तरह की सोच और बनी-बनाई परंपरा पर सवाल उठाने की क्षमता।',
        personality:
          'अंक 4 वाले लोग किसी बात को केवल इसलिए नहीं मानते कि सब मानते हैं। वे उन बारीकियों को देखते हैं जो दूसरों से छूट जाती हैं, अपने तरीके से व्यवस्थित काम करते हैं और अक्सर बिल्कुल अलग रास्ते से वही परिणाम पा लेते हैं। अंक ज्योतिष के अनुसार इनके जीवन में अचानक बदलाव सामान्य हैं।',
        behaviour:
          'काम में आप भरोसेमंद हैं, पर तरीका हमेशा अनुमानित नहीं होता। जो प्रक्रिया आपको अतार्किक लगे, उसे मानने का दबाव आपको पसंद नहीं। भरोसा होने तक आप अपनी असली राय अपने पास रखते हैं।',
        strengths: ['व्यावहारिक बुद्धि', 'नए तरीके', 'कठिन परिश्रम', 'ईमानदारी', 'समस्या सुलझाना', 'जटिलता संभालना'],
        weaknesses: ['बेचैनी', 'अधिकारियों से बहस', 'जोखिम पर ज्यादा सोचना', 'आराम न कर पाना', 'गलत समझे जाने का अहसास'],
        career:
          'परंपरागत रूप से तकनीक, अनुसंधान, इंजीनियरिंग, मशीनरी, विमानन, मीडिया, रियल एस्टेट, डेटा, लॉजिस्टिक्स और ऐसे हर क्षेत्र से जुड़ा है जहाँ अलग सोच का महत्व हो।',
        relationships:
          'आप वफादार पर निजी स्वभाव के होते हैं। जब आप केवल सोच रहे होते हैं, तब भी साथी को लगता है कि आप कुछ छिपा रहे हैं। अधूरी योजनाएँ भी समय रहते साझा करने से रिश्ते बहुत सहज हो जाते हैं।',
        general:
          'अंक ज्योतिष बताती है कि अंक 4 को अपनी चुनी हुई व्यवस्था से लाभ होता है: निश्चित दिनचर्या, स्पष्ट आर्थिक हिसाब और पूरी नींद इस अंक से जुड़ी बेचैनी को कम करते हैं।',
        colors: ['धूसर (ग्रे)', 'चमकीला नीला', 'खाकी'],
        notes: 'स्वामी ग्रह: राहु। परंपरागत रूप से शनिवार के उत्तरार्ध से संबंधित।',
      },
      mr: {
        name: 'व्यावहारिक व वेगळ्या विचारांचा',
        title: 'अंक 4 - राहू',
        summary: 'अंक 4 पारंपरिकपणे राहूशी जोडलेला आहे: व्यावहारिक बुद्धी, वेगळा विचार आणि रूढ नियमांवर प्रश्न विचारण्याची तयारी.',
        personality:
          'अंक 4 असलेल्या व्यक्ती केवळ सगळे करतात म्हणून काही स्वीकारत नाहीत. इतरांच्या नजरेतून सुटणारे बारकावे त्यांना दिसतात, ते स्वतःच्या पद्धतीने नियोजनबद्ध काम करतात आणि बऱ्याचदा पूर्ण वेगळ्या मार्गाने तोच निकाल मिळवतात. अंकशास्त्रानुसार त्यांच्या आयुष्यात अचानक बदल सामान्य असतात.',
        behaviour:
          'कामात तुम्ही विश्वासार्ह असता, पण पद्धत नेहमीच अपेक्षित नसते. जी प्रक्रिया तुम्हाला अतार्किक वाटते ती लादलेली आवडत नाही. विश्वास बसेपर्यंत तुम्ही खरे मत स्वतःजवळ ठेवता.',
        strengths: ['व्यावहारिक बुद्धी', 'नवे मार्ग', 'कष्ट करण्याची तयारी', 'प्रामाणिकपणा', 'समस्या सोडवणे', 'गुंतागुंत हाताळणे'],
        weaknesses: ['अस्वस्थता', 'वरिष्ठांशी वाद', 'धोक्यांचा अतिविचार', 'निवांत न होणे', 'गैरसमज झाल्याची भावना'],
        career:
          'पारंपरिकपणे तंत्रज्ञान, संशोधन, अभियांत्रिकी, यंत्रसामग्री, विमानसेवा, माध्यमे, स्थावर मालमत्ता, डेटा, लॉजिस्टिक्स आणि वेगळ्या विचारांना वाव देणाऱ्या क्षेत्रांशी संबंधित.',
        relationships:
          'तुम्ही निष्ठावान पण अंतर्मुख असता. तुम्ही केवळ विचार करत असताना देखील जोडीदाराला काहीतरी लपवले जात आहे असे वाटते. अपूर्ण योजनाही वेळेत सांगितल्यास नाते खूप सोपे होते.',
        general:
          'अंकशास्त्र सुचवते की अंक 4 ला स्वतः निवडलेल्या शिस्तीचा फायदा होतो: ठरलेला दिनक्रम, स्पष्ट आर्थिक हिशोब आणि पुरेशी झोप या अंकाशी जोडलेली अस्वस्थता कमी करतात.',
        colors: ['करडा', 'चमकदार निळा', 'खाकी'],
        notes: 'स्वामी ग्रह: राहू. पारंपरिकपणे शनिवारच्या उत्तरार्धाशी संबंधित.',
      },
    },
  },
  {
    number: 5,
    luckyNumbers: [1, 3, 5, 6],
    unfavourableNumbers: [],
    copy: {
      en: {
        name: 'The Communicator',
        title: 'Number 5 - Mercury',
        summary: 'Number 5 is traditionally associated with Mercury: quick thinking, communication, business sense and adaptability.',
        personality:
          'People with number 5 learn fast, talk easily with anyone and adjust to new situations without much difficulty. Numerology considers 5 the most flexible number, which is why it sits comfortably with almost every other number.',
        behaviour:
          'You get bored by repetition and look for variety. You negotiate well, notice opportunities early and often keep several plans running at the same time.',
        strengths: ['Quick learning', 'Communication', 'Business sense', 'Adaptability', 'Networking', 'Good humour'],
        weaknesses: ['Restlessness', 'Starting more than you finish', 'Impatience', 'Nervous energy', 'Avoiding long commitments'],
        career:
          'Traditionally associated with business, sales, marketing, trading, accountancy, journalism, travel, transport, software and any work built on communication.',
        relationships:
          'You are cheerful and easy to be around, but you need freedom and conversation. A partner who allows you space while keeping the relationship stable brings out your best.',
        general:
          'Numerology suggests that number 5 succeeds through communication and connections rather than force. Finishing what is started is traditionally the main lesson for this number.',
        colors: ['Green', 'Light grey', 'Turquoise'],
        notes: 'Ruling planet: Mercury (Budh). Traditionally linked with Wednesday.',
      },
      hi: {
        name: 'संवाद कुशल',
        title: 'अंक 5 - बुध',
        summary: 'अंक 5 परंपरागत रूप से बुध से जुड़ा है: तेज बुद्धि, संवाद, व्यापारिक समझ और लचीलापन।',
        personality:
          'अंक 5 वाले लोग जल्दी सीखते हैं, किसी से भी सहजता से बात कर लेते हैं और नई परिस्थितियों में आसानी से ढल जाते हैं। अंक ज्योतिष में 5 को सबसे लचीला अंक माना जाता है, इसलिए यह लगभग हर अंक के साथ सहज रहता है।',
        behaviour:
          'दोहराव से आप जल्दी ऊब जाते हैं और विविधता खोजते हैं। आप मोल-भाव अच्छा करते हैं, अवसर जल्दी पहचानते हैं और अक्सर एक साथ कई योजनाएँ चलाते हैं।',
        strengths: ['तेज सीखना', 'संवाद कौशल', 'व्यापारिक समझ', 'लचीलापन', 'संपर्क बनाना', 'हँसमुख स्वभाव'],
        weaknesses: ['बेचैनी', 'शुरू ज्यादा, पूरा कम', 'अधीरता', 'घबराहट भरी ऊर्जा', 'लंबे वादों से बचना'],
        career:
          'परंपरागत रूप से व्यापार, बिक्री, विपणन, ट्रेडिंग, लेखा, पत्रकारिता, यात्रा, परिवहन, सॉफ्टवेयर और संवाद पर आधारित हर काम से जुड़ा है।',
        relationships:
          'आप खुशमिजाज और सहज साथी होते हैं, पर आपको आज़ादी और बातचीत चाहिए। ऐसा साथी जो आपको जगह दे और रिश्ते को स्थिर रखे, आपका सर्वश्रेष्ठ रूप सामने लाता है।',
        general:
          'अंक ज्योतिष बताती है कि अंक 5 जोर-जबरदस्ती से नहीं, संवाद और संबंधों से सफल होता है। शुरू किए काम को पूरा करना इस अंक का मुख्य सबक माना जाता है।',
        colors: ['हरा', 'हल्का धूसर', 'फिरोज़ी'],
        notes: 'स्वामी ग्रह: बुध। परंपरागत रूप से बुधवार से संबंधित।',
      },
      mr: {
        name: 'संवादकुशल',
        title: 'अंक 5 - बुध',
        summary: 'अंक 5 पारंपरिकपणे बुधाशी जोडलेला आहे: चपळ बुद्धी, संवाद, व्यवसायिक समज आणि जुळवून घेण्याची क्षमता.',
        personality:
          'अंक 5 असलेल्या व्यक्ती लवकर शिकतात, कोणाशीही सहज बोलतात आणि नव्या परिस्थितीत विनासायास जुळवून घेतात. अंकशास्त्रात 5 हा सर्वात लवचिक अंक मानला जातो, म्हणूनच तो जवळपास प्रत्येक अंकासोबत सहज राहतो.',
        behaviour:
          'पुनरावृत्तीचा तुम्हाला लवकर कंटाळा येतो आणि तुम्ही विविधता शोधता. तुम्ही वाटाघाटी चांगल्या करता, संधी लवकर ओळखता आणि अनेकदा एकाच वेळी अनेक योजना चालवता.',
        strengths: ['जलद शिकणे', 'संवादकौशल्य', 'व्यवसायिक समज', 'लवचिकता', 'संपर्क जोडणे', 'खेळकर स्वभाव'],
        weaknesses: ['अस्वस्थता', 'सुरू जास्त, पूर्ण कमी', 'अधीरता', 'चिंतायुक्त ऊर्जा', 'दीर्घ बांधिलकी टाळणे'],
        career:
          'पारंपरिकपणे व्यवसाय, विक्री, विपणन, ट्रेडिंग, लेखापाल, पत्रकारिता, प्रवास, वाहतूक, सॉफ्टवेअर आणि संवादावर आधारित कोणत्याही कामाशी संबंधित.',
        relationships:
          'तुम्ही आनंदी आणि सहवासात सोपे असता, पण तुम्हाला मोकळीक आणि संवाद लागतो. मोकळीक देत नाते स्थिर ठेवणारा जोडीदार तुमचे सर्वोत्तम रूप बाहेर आणतो.',
        general:
          'अंकशास्त्र सुचवते की अंक 5 जोरजबरदस्तीने नव्हे तर संवाद व संपर्कातून यशस्वी होतो. सुरू केलेले पूर्ण करणे हा या अंकाचा मुख्य धडा मानला जातो.',
        colors: ['हिरवा', 'फिकट करडा', 'फिरोजी'],
        notes: 'स्वामी ग्रह: बुध. पारंपरिकपणे बुधवारशी संबंधित.',
      },
    },
  },
  {
    number: 6,
    luckyNumbers: [3, 5, 6, 9],
    unfavourableNumbers: [2],
    copy: {
      en: {
        name: 'The Harmoniser',
        title: 'Number 6 - Venus',
        summary: 'Number 6 is traditionally associated with Venus: beauty, comfort, family responsibility and an eye for quality.',
        personality:
          'People with number 6 care about how things look and how people feel. They are usually warm hosts, take family duties seriously and have refined taste in clothes, food, music or design. Numerology links this number strongly with love and comfort.',
        behaviour:
          'You attract people easily and dislike ugliness, rudeness and disorder. You will spend willingly on quality and on the people you love, and you expect appreciation in return.',
        strengths: ['Warmth', 'Artistic taste', 'Responsibility towards family', 'Charm', 'Sense of balance', 'Generosity'],
        weaknesses: ['Over-attachment to comfort', 'Avoiding hard conversations', 'Worrying about others opinions', 'Overspending', 'Possessiveness'],
        career:
          'Traditionally associated with design, fashion, interiors, beauty, hospitality, entertainment, jewellery, luxury retail, teaching arts and family businesses.',
        relationships:
          'Relationships matter deeply to you and you invest a lot in them. You are affectionate and dependable, but you can hold on too tightly. Giving your partner freedom strengthens rather than weakens the bond.',
        general:
          'Numerology suggests that number 6 does well in work that combines beauty with service to others. Balance between giving and expecting is traditionally the main lesson.',
        colors: ['White', 'Pastel blue', 'Rose pink'],
        notes: 'Ruling planet: Venus (Shukra). Traditionally linked with Friday.',
      },
      hi: {
        name: 'सौंदर्य और संतुलन',
        title: 'अंक 6 - शुक्र',
        summary: 'अंक 6 परंपरागत रूप से शुक्र से जुड़ा है: सौंदर्य, आराम, पारिवारिक जिम्मेदारी और गुणवत्ता की परख।',
        personality:
          'अंक 6 वाले लोगों को इस बात की परवाह होती है कि चीजें कैसी दिखती हैं और लोग कैसा महसूस करते हैं। ये आमतौर पर अच्छे मेजबान होते हैं, पारिवारिक कर्तव्यों को गंभीरता से लेते हैं और कपड़े, भोजन, संगीत या डिज़ाइन में इनकी पसंद परिष्कृत होती है। अंक ज्योतिष इस अंक को प्रेम और सुख-सुविधा से गहराई से जोड़ती है।',
        behaviour:
          'लोग आपकी ओर सहज ही आकर्षित होते हैं; कुरूपता, कठोरता और अव्यवस्था आपको पसंद नहीं। गुणवत्ता पर और अपनों पर आप खुले मन से खर्च करते हैं और बदले में सराहना चाहते हैं।',
        strengths: ['स्नेह', 'कलात्मक रुचि', 'पारिवारिक जिम्मेदारी', 'आकर्षण', 'संतुलन की समझ', 'उदारता'],
        weaknesses: ['आराम से अत्यधिक लगाव', 'कठिन बातचीत टालना', 'लोगों की राय की चिंता', 'अधिक खर्च', 'अधिकार जताना'],
        career:
          'परंपरागत रूप से डिज़ाइन, फैशन, इंटीरियर, सौंदर्य, आतिथ्य, मनोरंजन, आभूषण, लक्ज़री रिटेल, कला शिक्षण और पारिवारिक व्यवसाय से जुड़ा है।',
        relationships:
          'रिश्ते आपके लिए बहुत मायने रखते हैं और आप उनमें बहुत कुछ लगाते हैं। आप स्नेही और भरोसेमंद हैं, पर कभी-कभी पकड़ बहुत कस लेते हैं। साथी को आज़ादी देने से बंधन कमजोर नहीं, मजबूत होता है।',
        general:
          'अंक ज्योतिष बताती है कि अंक 6 ऐसे कामों में अच्छा करता है जिनमें सौंदर्य और सेवा दोनों हों। देने और अपेक्षा रखने के बीच संतुलन इस अंक का मुख्य सबक माना जाता है।',
        colors: ['सफेद', 'हल्का नीला', 'गुलाबी'],
        notes: 'स्वामी ग्रह: शुक्र। परंपरागत रूप से शुक्रवार से संबंधित।',
      },
      mr: {
        name: 'सौंदर्य व संतुलन',
        title: 'अंक 6 - शुक्र',
        summary: 'अंक 6 पारंपरिकपणे शुक्राशी जोडलेला आहे: सौंदर्य, आराम, कौटुंबिक जबाबदारी आणि दर्जाची पारख.',
        personality:
          'अंक 6 असलेल्या व्यक्तींना गोष्टी कशा दिसतात आणि माणसांना कसे वाटते याची काळजी असते. ते सहसा उत्तम आदरातिथ्य करतात, कौटुंबिक कर्तव्ये गांभीर्याने घेतात आणि कपडे, अन्न, संगीत किंवा डिझाईनमधील त्यांची आवड नाजूक असते. अंकशास्त्र या अंकाला प्रेम आणि सुखसोयींशी घट्ट जोडते.',
        behaviour:
          'लोक तुमच्याकडे सहज आकर्षित होतात; कुरूपता, उद्धटपणा आणि अव्यवस्था तुम्हाला आवडत नाही. दर्जावर आणि आपल्या माणसांवर तुम्ही मनापासून खर्च करता आणि बदल्यात कौतुकाची अपेक्षा ठेवता.',
        strengths: ['प्रेमळपणा', 'कलात्मक अभिरुची', 'कौटुंबिक जबाबदारी', 'आकर्षकता', 'संतुलनाची जाण', 'औदार्य'],
        weaknesses: ['आरामाची अतिआसक्ती', 'कठीण संवाद टाळणे', 'लोक काय म्हणतील याची चिंता', 'अतिखर्च', 'हक्क गाजवणे'],
        career:
          'पारंपरिकपणे डिझाईन, फॅशन, इंटिरियर, सौंदर्य, आतिथ्य, मनोरंजन, दागिने, लक्झरी विक्री, कला शिक्षण आणि कौटुंबिक व्यवसायाशी संबंधित.',
        relationships:
          'नाती तुमच्यासाठी खूप महत्त्वाची असतात आणि तुम्ही त्यात खूप गुंतवता. तुम्ही प्रेमळ व विश्वासार्ह असता, पण कधी कधी पकड खूप घट्ट होते. जोडीदाराला मोकळीक दिल्याने नाते कमजोर नव्हे तर मजबूत होते.',
        general:
          'अंकशास्त्र सुचवते की अंक 6 सौंदर्य आणि सेवा एकत्र असलेल्या कामात चांगले करतो. देणे आणि अपेक्षा यामधील संतुलन हा या अंकाचा मुख्य धडा मानला जातो.',
        colors: ['पांढरा', 'फिकट निळा', 'गुलाबी'],
        notes: 'स्वामी ग्रह: शुक्र. पारंपरिकपणे शुक्रवारशी संबंधित.',
      },
    },
  },
  {
    number: 7,
    luckyNumbers: [1, 2, 4, 7],
    unfavourableNumbers: [9],
    copy: {
      en: {
        name: 'The Seeker',
        title: 'Number 7 - Ketu',
        summary: 'Number 7 is traditionally associated with Ketu: depth, research, intuition and an interest in what lies beneath the surface.',
        personality:
          'People with number 7 need to understand things properly before accepting them. They enjoy solitude, notice patterns others miss and are often drawn to philosophy, research or spirituality. Numerology suggests a strong inner life that is not always visible from outside.',
        behaviour:
          'You observe more than you speak, dislike shallow conversation and keep a small circle of trusted people. You need quiet time regularly, and you become irritable without it.',
        strengths: ['Analytical depth', 'Intuition', 'Independence of thought', 'Patience with detail', 'Honesty', 'Calm under pressure'],
        weaknesses: ['Withdrawing when hurt', 'Over-analysis', 'Difficulty expressing feelings', 'Scepticism', 'Delay in decisions'],
        career:
          'Traditionally associated with research, analysis, medicine, law, technology, teaching, spirituality, writing, investigation and specialist consulting.',
        relationships:
          'You are sincere and undemanding, but not naturally expressive. A partner may read your silence as distance. Saying plainly what you feel, even briefly, prevents most misunderstandings.',
        general:
          'Numerology suggests that number 7 grows through study, reflection and honest self-examination. Rushing important decisions is traditionally discouraged for this number.',
        colors: ['Light grey', 'Sea green', 'Smoky white'],
        notes: 'Ruling planet: Ketu. Traditionally linked with intuition and inner enquiry.',
      },
      hi: {
        name: 'खोजी और चिंतनशील',
        title: 'अंक 7 - केतु',
        summary: 'अंक 7 परंपरागत रूप से केतु से जुड़ा है: गहराई, अनुसंधान, अंतर्ज्ञान और सतह के नीचे छिपी बात जानने की रुचि।',
        personality:
          'अंक 7 वाले लोग किसी बात को मानने से पहले ठीक से समझना चाहते हैं। इन्हें एकांत पसंद है, ये उन बातों को देख लेते हैं जो दूसरों से छूट जाती हैं और अक्सर दर्शन, अनुसंधान या अध्यात्म की ओर झुकते हैं। अंक ज्योतिष के अनुसार इनका भीतरी जीवन गहरा होता है, जो बाहर से हमेशा नहीं दिखता।',
        behaviour:
          'आप बोलने से ज्यादा देखते हैं, सतही बातचीत पसंद नहीं करते और भरोसेमंद लोगों का छोटा दायरा रखते हैं। आपको नियमित रूप से शांत समय चाहिए; उसके बिना चिड़चिड़ापन आ जाता है।',
        strengths: ['विश्लेषण की गहराई', 'अंतर्ज्ञान', 'स्वतंत्र सोच', 'बारीकी में धैर्य', 'ईमानदारी', 'दबाव में शांति'],
        weaknesses: ['चोट लगने पर अलग हो जाना', 'अत्यधिक विश्लेषण', 'भावनाएँ व्यक्त करने में कठिनाई', 'संदेह', 'निर्णय में देरी'],
        career:
          'परंपरागत रूप से अनुसंधान, विश्लेषण, चिकित्सा, कानून, तकनीक, शिक्षण, अध्यात्म, लेखन, जाँच-पड़ताल और विशेषज्ञ परामर्श से जुड़ा है।',
        relationships:
          'आप सच्चे और कम माँग वाले होते हैं, पर स्वभाव से कम अभिव्यक्त करते हैं। साथी आपकी चुप्पी को दूरी समझ सकता है। जो महसूस करते हैं उसे सीधे, चाहे संक्षेप में, कह देने से अधिकतर गलतफहमियाँ टल जाती हैं।',
        general:
          'अंक ज्योतिष बताती है कि अंक 7 अध्ययन, चिंतन और ईमानदार आत्म-परीक्षण से बढ़ता है। महत्वपूर्ण निर्णयों में जल्दबाजी इस अंक के लिए उचित नहीं मानी जाती।',
        colors: ['हल्का धूसर', 'समुद्री हरा', 'धुँधला सफेद'],
        notes: 'स्वामी ग्रह: केतु। परंपरागत रूप से अंतर्ज्ञान और आत्म-खोज से संबंधित।',
      },
      mr: {
        name: 'शोध घेणारा',
        title: 'अंक 7 - केतू',
        summary: 'अंक 7 पारंपरिकपणे केतूशी जोडलेला आहे: खोली, संशोधन, अंतर्ज्ञान आणि पृष्ठभागाखालील गोष्टी जाणून घेण्याची आवड.',
        personality:
          'अंक 7 असलेल्या व्यक्तींना काही स्वीकारण्यापूर्वी ते नीट समजून घ्यायचे असते. त्यांना एकांत आवडतो, इतरांच्या नजरेतून सुटणारे नमुने त्यांना दिसतात आणि ते बऱ्याचदा तत्त्वज्ञान, संशोधन किंवा अध्यात्माकडे ओढले जातात. अंकशास्त्रानुसार त्यांचे आंतरिक जीवन खोल असते, जे बाहेरून नेहमी दिसत नाही.',
        behaviour:
          'तुम्ही बोलण्यापेक्षा निरीक्षण जास्त करता, वरवरच्या गप्पा आवडत नाहीत आणि विश्वासू माणसांचे छोटे वर्तुळ ठेवता. तुम्हाला नियमित शांत वेळ लागतो; तो नसेल तर चिडचिड होते.',
        strengths: ['विश्लेषणाची खोली', 'अंतर्ज्ञान', 'स्वतंत्र विचार', 'बारकाव्यांतील संयम', 'प्रामाणिकपणा', 'दबावात शांतता'],
        weaknesses: ['दुखावल्यावर अलिप्त होणे', 'अतिविश्लेषण', 'भावना व्यक्त करण्यात अडचण', 'संशय', 'निर्णयास विलंब'],
        career:
          'पारंपरिकपणे संशोधन, विश्लेषण, वैद्यकीय क्षेत्र, कायदा, तंत्रज्ञान, शिक्षण, अध्यात्म, लेखन, तपास आणि तज्ज्ञ सल्लागार कामाशी संबंधित.',
        relationships:
          'तुम्ही प्रामाणिक आणि कमी अपेक्षा ठेवणारे असता, पण स्वभावाने कमी व्यक्त होता. जोडीदार तुमच्या मौनाला अंतर समजू शकतो. जे वाटते ते थोडक्यात का होईना स्पष्ट सांगितल्यास बहुतेक गैरसमज टळतात.',
        general:
          'अंकशास्त्र सुचवते की अंक 7 अभ्यास, चिंतन आणि प्रामाणिक आत्मपरीक्षणातून वाढतो. महत्त्वाच्या निर्णयांत घाई या अंकासाठी योग्य मानली जात नाही.',
        colors: ['फिकट करडा', 'समुद्री हिरवा', 'धुरकट पांढरा'],
        notes: 'स्वामी ग्रह: केतू. पारंपरिकपणे अंतर्ज्ञान व आत्मशोधाशी संबंधित.',
      },
    },
  },
  {
    number: 8,
    luckyNumbers: [3, 5, 6, 8],
    unfavourableNumbers: [1, 9],
    copy: {
      en: {
        name: 'The Builder',
        title: 'Number 8 - Saturn',
        summary: 'Number 8 is traditionally associated with Saturn: discipline, endurance, justice and results that arrive slowly but last.',
        personality:
          'People with number 8 are serious about responsibility. They work steadily, keep their word, and are often trusted with money or authority. Numerology suggests their progress comes later than others but is usually more durable.',
        behaviour:
          'You plan for the long term, dislike shortcuts and judge people by their consistency. Setbacks do not stop you, though you may carry them quietly for a long time.',
        strengths: ['Discipline', 'Endurance', 'Fairness', 'Organisation', 'Financial sense', 'Reliability'],
        weaknesses: ['Taking on too much alone', 'Rigidity', 'Delayed rewards causing frustration', 'Holding grudges', 'Difficulty relaxing'],
        career:
          'Traditionally associated with administration, finance, law, construction, manufacturing, mining, agriculture, logistics, insurance and long-term institutional work.',
        relationships:
          'You are steady and protective rather than romantic in style. Partners value your reliability but need warmth expressed openly. Small gestures matter more than you may assume.',
        general:
          'Numerology suggests that number 8 rewards patience. Traditionally this number is associated with hard-earned rather than easy success, and with fairness towards those who work under you.',
        colors: ['Dark blue', 'Black', 'Deep grey'],
        notes: 'Ruling planet: Saturn (Shani). Traditionally linked with Saturday.',
      },
      hi: {
        name: 'परिश्रमी निर्माता',
        title: 'अंक 8 - शनि',
        summary: 'अंक 8 परंपरागत रूप से शनि से जुड़ा है: अनुशासन, सहनशीलता, न्याय और ऐसे परिणाम जो देर से आते हैं पर टिकते हैं।',
        personality:
          'अंक 8 वाले लोग जिम्मेदारी को गंभीरता से लेते हैं। ये लगातार काम करते हैं, वचन निभाते हैं और अक्सर धन या अधिकार इन पर भरोसे के साथ सौंपा जाता है। अंक ज्योतिष के अनुसार इनकी प्रगति दूसरों से देर से आती है पर अधिक टिकाऊ होती है।',
        behaviour:
          'आप लंबी अवधि की योजना बनाते हैं, छोटे रास्ते पसंद नहीं करते और लोगों को उनकी निरंतरता से आँकते हैं। असफलताएँ आपको रोकती नहीं, पर आप उन्हें लंबे समय तक चुपचाप मन में रख सकते हैं।',
        strengths: ['अनुशासन', 'सहनशीलता', 'न्यायप्रियता', 'व्यवस्थित कार्यशैली', 'आर्थिक समझ', 'भरोसेमंद स्वभाव'],
        weaknesses: ['अकेले बहुत बोझ उठाना', 'कठोरता', 'देर से फल मिलने पर निराशा', 'मन में बात रखना', 'आराम न कर पाना'],
        career:
          'परंपरागत रूप से प्रशासन, वित्त, कानून, निर्माण, विनिर्माण, खनन, कृषि, लॉजिस्टिक्स, बीमा और दीर्घकालिक संस्थागत कार्य से जुड़ा है।',
        relationships:
          'आप रोमांटिक शैली से ज्यादा स्थिर और रक्षा करने वाले होते हैं। साथी आपकी विश्वसनीयता की कद्र करते हैं, पर उन्हें खुलकर व्यक्त किया गया स्नेह भी चाहिए। छोटे-छोटे इशारे आपकी सोच से कहीं ज्यादा मायने रखते हैं।',
        general:
          'अंक ज्योतिष बताती है कि अंक 8 धैर्य का फल देता है। परंपरागत रूप से यह अंक आसान नहीं, मेहनत से अर्जित सफलता से और अपने अधीन काम करने वालों के साथ न्याय से जुड़ा है।',
        colors: ['गहरा नीला', 'काला', 'गहरा धूसर'],
        notes: 'स्वामी ग्रह: शनि। परंपरागत रूप से शनिवार से संबंधित।',
      },
      mr: {
        name: 'कष्टाळू निर्माता',
        title: 'अंक 8 - शनी',
        summary: 'अंक 8 पारंपरिकपणे शनीशी जोडलेला आहे: शिस्त, सहनशीलता, न्याय आणि उशिरा येणारे पण टिकणारे निकाल.',
        personality:
          'अंक 8 असलेल्या व्यक्ती जबाबदारी गांभीर्याने घेतात. ते सातत्याने काम करतात, शब्द पाळतात आणि पैसा किंवा अधिकार त्यांच्यावर विश्वासाने सोपवला जातो. अंकशास्त्रानुसार त्यांची प्रगती इतरांपेक्षा उशिरा येते पण अधिक टिकाऊ असते.',
        behaviour:
          'तुम्ही दीर्घकालीन नियोजन करता, शॉर्टकट आवडत नाहीत आणि माणसांना त्यांच्या सातत्यावरून जोखता. अपयश तुम्हाला थांबवत नाही, पण ते तुम्ही बराच काळ मनात ठेवू शकता.',
        strengths: ['शिस्त', 'सहनशीलता', 'न्यायबुद्धी', 'व्यवस्थितपणा', 'आर्थिक समज', 'विश्वासार्हता'],
        weaknesses: ['एकट्याने खूप ओझे घेणे', 'ताठरपणा', 'उशिरा फळ मिळाल्याने निराशा', 'मनात राग ठेवणे', 'निवांत न होणे'],
        career:
          'पारंपरिकपणे प्रशासन, वित्त, कायदा, बांधकाम, उत्पादन, खाणकाम, शेती, लॉजिस्टिक्स, विमा आणि दीर्घकालीन संस्थात्मक कामाशी संबंधित.',
        relationships:
          'तुम्ही रोमँटिक शैलीपेक्षा स्थिर आणि संरक्षण करणारे असता. जोडीदार तुमच्या विश्वासार्हतेची कदर करतो, पण त्यांना उघडपणे व्यक्त केलेला जिव्हाळाही हवा असतो. छोट्या कृती तुम्हाला वाटते त्यापेक्षा जास्त महत्त्वाच्या ठरतात.',
        general:
          'अंकशास्त्र सुचवते की अंक 8 संयमाचे फळ देतो. पारंपरिकपणे हा अंक सोप्या नव्हे तर कष्टाने मिळवलेल्या यशाशी आणि हाताखालच्या माणसांशी न्यायाने वागण्याशी जोडला जातो.',
        colors: ['गडद निळा', 'काळा', 'गडद करडा'],
        notes: 'स्वामी ग्रह: शनी. पारंपरिकपणे शनिवारशी संबंधित.',
      },
    },
  },
  {
    number: 9,
    luckyNumbers: [1, 3, 6, 9],
    unfavourableNumbers: [2, 7],
    copy: {
      en: {
        name: 'The Warrior',
        title: 'Number 9 - Mars',
        summary: 'Number 9 is traditionally associated with Mars: energy, courage, action and a strong sense of right and wrong.',
        personality:
          'People with number 9 act rather than wait. They are direct, protective of family and friends, and quick to stand up when something feels unfair. Numerology suggests high physical and mental energy that needs a proper outlet.',
        behaviour:
          'You commit fully once you decide, dislike indecision in others and prefer to settle matters immediately rather than let them linger. Your temper can rise quickly and settle just as quickly.',
        strengths: ['Courage', 'Energy', 'Loyalty', 'Determination', 'Protectiveness', 'Willingness to help'],
        weaknesses: ['Short temper', 'Impatience', 'Acting before thinking', 'Arguing', 'Taking on other people fights'],
        career:
          'Traditionally associated with defence, police, sports, surgery, engineering, construction, manufacturing, land and property, and any demanding physical or high-pressure work.',
        relationships:
          'You are passionate and protective, and you defend your partner strongly. The same intensity can cause friction over small things. Pausing before responding is traditionally the most useful habit for this number.',
        general:
          'Numerology suggests that number 9 does best with a clear challenge and regular physical activity. Energy without direction usually turns into irritation.',
        colors: ['Red', 'Maroon', 'Coral'],
        notes: 'Ruling planet: Mars (Mangal). Traditionally linked with Tuesday.',
      },
      hi: {
        name: 'ऊर्जावान और साहसी',
        title: 'अंक 9 - मंगल',
        summary: 'अंक 9 परंपरागत रूप से मंगल से जुड़ा है: ऊर्जा, साहस, कर्म और सही-गलत की मजबूत समझ।',
        personality:
          'अंक 9 वाले लोग इंतजार करने के बजाय कर्म करते हैं। ये स्पष्टवादी होते हैं, परिवार और मित्रों की रक्षा करते हैं और अन्याय दिखने पर तुरंत खड़े हो जाते हैं। अंक ज्योतिष के अनुसार इनमें शारीरिक और मानसिक ऊर्जा अधिक होती है, जिसे सही दिशा चाहिए।',
        behaviour:
          'एक बार तय करने के बाद आप पूरी तरह जुट जाते हैं, दूसरों की दुविधा आपको पसंद नहीं और आप बात को टालने के बजाय तुरंत सुलझाना चाहते हैं। गुस्सा जितनी जल्दी आता है, उतनी ही जल्दी उतर भी जाता है।',
        strengths: ['साहस', 'ऊर्जा', 'वफादारी', 'दृढ़ संकल्प', 'रक्षा करने का भाव', 'मदद के लिए तत्परता'],
        weaknesses: ['जल्दी गुस्सा', 'अधीरता', 'बिना सोचे कदम उठाना', 'बहस', 'दूसरों की लड़ाई अपने ऊपर लेना'],
        career:
          'परंपरागत रूप से रक्षा, पुलिस, खेल, शल्य चिकित्सा, इंजीनियरिंग, निर्माण, विनिर्माण, भूमि व संपत्ति और शारीरिक या दबाव भरे कार्यों से जुड़ा है।',
        relationships:
          'आप भावुक और रक्षा करने वाले हैं, साथी का पूरा साथ देते हैं। यही तीव्रता छोटी बातों पर टकराव भी पैदा कर सकती है। जवाब देने से पहले एक क्षण रुकना इस अंक के लिए सबसे उपयोगी आदत मानी जाती है।',
        general:
          'अंक ज्योतिष बताती है कि अंक 9 को स्पष्ट चुनौती और नियमित शारीरिक गतिविधि से सबसे अच्छा लाभ होता है। दिशा के बिना ऊर्जा आमतौर पर चिड़चिड़ाहट बन जाती है।',
        colors: ['लाल', 'मैरून', 'मूँगा रंग'],
        notes: 'स्वामी ग्रह: मंगल। परंपरागत रूप से मंगलवार से संबंधित।',
      },
      mr: {
        name: 'ऊर्जावान व धाडसी',
        title: 'अंक 9 - मंगळ',
        summary: 'अंक 9 पारंपरिकपणे मंगळाशी जोडलेला आहे: ऊर्जा, धाडस, कृती आणि योग्य-अयोग्याची ठाम जाणीव.',
        personality:
          'अंक 9 असलेल्या व्यक्ती वाट पाहण्यापेक्षा कृती करतात. ते स्पष्टवक्ते असतात, कुटुंब व मित्रांचे रक्षण करतात आणि अन्याय दिसताच लगेच उभे राहतात. अंकशास्त्रानुसार त्यांच्यात शारीरिक व मानसिक ऊर्जा जास्त असते, तिला योग्य दिशा लागते.',
        behaviour:
          'एकदा ठरवले की तुम्ही पूर्णपणे झोकून देता, इतरांची चालढकल आवडत नाही आणि गोष्टी लांबवण्यापेक्षा लगेच निकाली काढायला आवडते. राग जितक्या लवकर येतो तितक्याच लवकर निवळतो.',
        strengths: ['धाडस', 'ऊर्जा', 'निष्ठा', 'निश्चय', 'संरक्षक वृत्ती', 'मदतीची तयारी'],
        weaknesses: ['लवकर राग येणे', 'अधीरता', 'विचार न करता कृती', 'वाद घालणे', 'दुसऱ्यांची भांडणे अंगावर घेणे'],
        career:
          'पारंपरिकपणे संरक्षण, पोलीस, क्रीडा, शस्त्रक्रिया, अभियांत्रिकी, बांधकाम, उत्पादन, जमीन व मालमत्ता आणि शारीरिक किंवा दबावाच्या कामाशी संबंधित.',
        relationships:
          'तुम्ही उत्कट व संरक्षण करणारे असता आणि जोडीदाराच्या पाठीशी ठाम उभे राहता. हीच तीव्रता छोट्या गोष्टींवरून खटके निर्माण करू शकते. उत्तर देण्यापूर्वी क्षणभर थांबणे ही या अंकासाठी सर्वात उपयुक्त सवय मानली जाते.',
        general:
          'अंकशास्त्र सुचवते की अंक 9 ला स्पष्ट आव्हान आणि नियमित शारीरिक हालचालीचा सर्वाधिक फायदा होतो. दिशा नसलेली ऊर्जा सहसा चिडचिडेपणात बदलते.',
        colors: ['लाल', 'मरून', 'प्रवाळ रंग'],
        notes: 'स्वामी ग्रह: मंगळ. पारंपरिकपणे मंगळवारशी संबंधित.',
      },
    },
  },
];
