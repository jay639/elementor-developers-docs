import { NUMBER_SEEDS, type SeedLocale } from './numbers';

/**
 * Seed content for the 81 Mulank x Bhagyank combinations, in all three locales.
 *
 * The baseline text is composed from the traits of the driver number (Mulank)
 * and the conductor number (Bhagyank) so that every one of the 81 rows is real,
 * specific content rather than a placeholder. Administrators refine any row from
 * the admin panel; the app always reads the stored row, and falls back to the
 * two individual number interpretations only when a row is missing or unpublished.
 */

interface Trait {
  /** Short label, e.g. "leadership and initiative". */
  driver: string;
  /** How the number shapes the direction of life. */
  conductor: string;
  /** One word summary used in the title. */
  label: string;
  /** Practical recommendation associated with this number. */
  advice: string;
}

const TRAITS: Record<SeedLocale, Record<number, Trait>> = {
  en: {
    1: { label: 'Leader', driver: 'leadership, self-belief and the urge to start things yourself', conductor: 'independent work, responsibility and recognition earned in your own name', advice: 'set one clear goal of your own and protect time for it' },
    2: { label: 'Nurturer', driver: 'sensitivity, imagination and an instinct for how people feel', conductor: 'partnerships, teamwork and work that involves caring for others', advice: 'guard your peace of mind and speak about feelings before they build up' },
    3: { label: 'Teacher', driver: 'knowledge, expression and a natural habit of guiding others', conductor: 'learning, teaching and steady growth through discipline', advice: 'keep studying, and offer advice only where it is wanted' },
    4: { label: 'Innovator', driver: 'practical intelligence and an unconventional way of solving problems', conductor: 'sudden changes, technical work and progress through your own methods', advice: 'build a routine you choose yourself and keep your finances clear' },
    5: { label: 'Communicator', driver: 'quick thinking, adaptability and easy communication', conductor: 'business, connections and opportunities that arrive through people', advice: 'finish what you start before taking up the next idea' },
    6: { label: 'Harmoniser', driver: 'warmth, artistic taste and responsibility towards family', conductor: 'comfort, relationships and work connected with beauty or service', advice: 'balance what you give with what you expect in return' },
    7: { label: 'Seeker', driver: 'depth, analysis and the need to understand before accepting', conductor: 'research, specialisation and growth through reflection', advice: 'keep quiet time in your week and say plainly what you feel' },
    8: { label: 'Builder', driver: 'discipline, endurance and a serious sense of responsibility', conductor: 'long-term building, financial stability and results that come slowly', advice: 'be patient with timing and share the load instead of carrying it alone' },
    9: { label: 'Warrior', driver: 'energy, courage and a strong sense of right and wrong', conductor: 'action, protection of others and work that demands stamina', advice: 'give your energy a physical outlet and pause before reacting' },
  },
  hi: {
    1: { label: 'नेतृत्वकर्ता', driver: 'नेतृत्व, आत्मविश्वास और खुद कुछ शुरू करने की प्रेरणा', conductor: 'स्वतंत्र कार्य, जिम्मेदारी और अपने नाम से मिली पहचान', advice: 'अपना एक स्पष्ट लक्ष्य तय करें और उसके लिए समय सुरक्षित रखें' },
    2: { label: 'सहयोगी', driver: 'संवेदनशीलता, कल्पनाशीलता और दूसरों की भावनाएँ समझने की समझ', conductor: 'साझेदारी, टीम वर्क और दूसरों की देखभाल से जुड़ा काम', advice: 'अपने मन की शांति बचाकर रखें और भावनाएँ जमा होने से पहले कह दें' },
    3: { label: 'मार्गदर्शक', driver: 'ज्ञान, अभिव्यक्ति और दूसरों का मार्गदर्शन करने की स्वाभाविक आदत', conductor: 'सीखना, सिखाना और अनुशासन से निरंतर वृद्धि', advice: 'अध्ययन जारी रखें और सलाह वहीं दें जहाँ माँगी जाए' },
    4: { label: 'नवप्रवर्तक', driver: 'व्यावहारिक बुद्धि और समस्या सुलझाने का अलग तरीका', conductor: 'अचानक बदलाव, तकनीकी काम और अपने तरीकों से प्रगति', advice: 'अपनी चुनी हुई दिनचर्या बनाएँ और आर्थिक हिसाब स्पष्ट रखें' },
    5: { label: 'संवाद कुशल', driver: 'तेज सोच, लचीलापन और सहज संवाद', conductor: 'व्यापार, संपर्क और लोगों के माध्यम से आने वाले अवसर', advice: 'नया विचार उठाने से पहले शुरू किया काम पूरा करें' },
    6: { label: 'संतुलनकर्ता', driver: 'स्नेह, कलात्मक रुचि और परिवार के प्रति जिम्मेदारी', conductor: 'सुख-सुविधा, रिश्ते और सौंदर्य या सेवा से जुड़ा काम', advice: 'जो देते हैं और जो अपेक्षा रखते हैं, उनमें संतुलन रखें' },
    7: { label: 'खोजी', driver: 'गहराई, विश्लेषण और मानने से पहले समझने की जरूरत', conductor: 'अनुसंधान, विशेषज्ञता और चिंतन से वृद्धि', advice: 'सप्ताह में शांत समय रखें और जो महसूस करते हैं वह सीधे कहें' },
    8: { label: 'निर्माता', driver: 'अनुशासन, सहनशीलता और जिम्मेदारी की गंभीर समझ', conductor: 'दीर्घकालिक निर्माण, आर्थिक स्थिरता और धीरे-धीरे मिलने वाले परिणाम', advice: 'समय पर भरोसा रखें और बोझ अकेले उठाने के बजाय बाँटें' },
    9: { label: 'योद्धा', driver: 'ऊर्जा, साहस और सही-गलत की मजबूत समझ', conductor: 'कर्म, दूसरों की रक्षा और सहनशक्ति माँगने वाला काम', advice: 'ऊर्जा को शारीरिक दिशा दें और प्रतिक्रिया से पहले रुकें' },
  },
  mr: {
    1: { label: 'नेतृत्व करणारा', driver: 'नेतृत्व, आत्मविश्वास आणि स्वतः काही सुरू करण्याची प्रेरणा', conductor: 'स्वतंत्र काम, जबाबदारी आणि स्वतःच्या नावाने मिळालेली ओळख', advice: 'स्वतःचे एक स्पष्ट ध्येय ठरवा आणि त्यासाठी वेळ राखून ठेवा' },
    2: { label: 'सहकारी', driver: 'संवेदनशीलता, कल्पकता आणि इतरांच्या भावना ओळखण्याची जाण', conductor: 'भागीदारी, सांघिक काम आणि इतरांची काळजी घेणारे काम', advice: 'मनःशांती जपा आणि भावना साठण्याआधी बोलून टाका' },
    3: { label: 'मार्गदर्शक', driver: 'ज्ञान, अभिव्यक्ती आणि इतरांना मार्गदर्शन करण्याची नैसर्गिक सवय', conductor: 'शिकणे, शिकवणे आणि शिस्तीतून सातत्यपूर्ण वाढ', advice: 'अभ्यास सुरू ठेवा आणि सल्ला मागितला तिथेच द्या' },
    4: { label: 'नवनिर्माता', driver: 'व्यावहारिक बुद्धी आणि समस्या सोडवण्याची वेगळी पद्धत', conductor: 'अचानक बदल, तांत्रिक काम आणि स्वतःच्या पद्धतीने प्रगती', advice: 'स्वतः निवडलेला दिनक्रम ठेवा आणि आर्थिक हिशोब स्पष्ट ठेवा' },
    5: { label: 'संवादकुशल', driver: 'चपळ विचार, लवचिकता आणि सहज संवाद', conductor: 'व्यवसाय, संपर्क आणि माणसांमधून येणाऱ्या संधी', advice: 'नवी कल्पना घेण्याआधी सुरू केलेले काम पूर्ण करा' },
    6: { label: 'संतुलन साधणारा', driver: 'प्रेमळपणा, कलात्मक अभिरुची आणि कुटुंबाप्रती जबाबदारी', conductor: 'सुखसोयी, नाती आणि सौंदर्य किंवा सेवेशी जोडलेले काम', advice: 'जे देता आणि जी अपेक्षा ठेवता त्यात संतुलन ठेवा' },
    7: { label: 'शोधक', driver: 'खोली, विश्लेषण आणि स्वीकारण्याआधी समजून घेण्याची गरज', conductor: 'संशोधन, विशेषज्ञता आणि चिंतनातून वाढ', advice: 'आठवड्यात शांत वेळ ठेवा आणि जे वाटते ते स्पष्ट सांगा' },
    8: { label: 'निर्माता', driver: 'शिस्त, सहनशीलता आणि जबाबदारीची गंभीर जाण', conductor: 'दीर्घकालीन उभारणी, आर्थिक स्थैर्य आणि हळू मिळणारे निकाल', advice: 'वेळेवर विश्वास ठेवा आणि ओझे एकट्याने न उचलता वाटून घ्या' },
    9: { label: 'योद्धा', driver: 'ऊर्जा, धाडस आणि योग्य-अयोग्याची ठाम जाणीव', conductor: 'कृती, इतरांचे रक्षण आणि दमसास मागणारे काम', advice: 'ऊर्जेला शारीरिक वाट द्या आणि प्रतिक्रिया देण्याआधी थांबा' },
  },
};

const TEMPLATES: Record<SeedLocale, {
  title: (m: number, b: number, ml: string, bl: string) => string;
  same: (m: number, t: Trait) => string;
  mixed: (m: number, b: number, mt: Trait, bt: Trait) => string;
  personality: (mt: Trait, bt: Trait) => string;
  career: (mt: Trait, bt: Trait) => string;
  relationships: (mt: Trait, bt: Trait) => string;
  recommendations: (mt: Trait, bt: Trait) => string;
  strengthLead: string;
  challengeLead: string;
}> = {
  en: {
    title: (m, b, ml, bl) => `Mulank ${m} with Bhagyank ${b} - ${ml} guided by the ${bl} path`,
    same: (m, t) =>
      `Your Mulank and your Bhagyank are both ${m}, so the qualities of this number are doubled in your chart. Numerology suggests ${t.driver} shows up in almost everything you do, and the direction of your life also points towards ${t.conductor}. This makes you consistent and easy to recognise, but it also means there is little natural balance from a second number - the strengths and the difficulties of ${m} both become stronger.`,
    mixed: (m, b, mt, bt) =>
      `Your Mulank ${m} gives you ${mt.driver}. Your Bhagyank ${b} shapes the direction your life tends to take, which is towards ${bt.conductor}. Numerology suggests that your day to day nature comes from ${m} while the opportunities and long term path come from ${b}. When these two work together you make steady progress; when you ignore one of them, life feels like effort without result.`,
    personality: (mt, bt) =>
      `In everyday behaviour you show ${mt.driver}. Underneath that, your choices keep moving you towards ${bt.conductor}. People usually notice the first quality quickly and understand the second only after knowing you for a while.`,
    career: (mt, bt) =>
      `Work that lets you use ${mt.driver} while moving towards ${bt.conductor} suits you best. A job that uses only one of the two usually feels incomplete after a few years.`,
    relationships: (mt, bt) =>
      `In relationships you bring ${mt.driver}. What you actually need from a partner is support for ${bt.conductor}. Saying this openly prevents most of the friction this combination is associated with.`,
    recommendations: (mt, bt) => `Traditionally recommended for this combination: ${mt.advice}; and ${bt.advice}.`,
    strengthLead: '',
    challengeLead: '',
  },
  hi: {
    title: (m, b, ml, bl) => `मूलांक ${m} और भाग्यांक ${b} - ${ml}, ${bl} की दिशा के साथ`,
    same: (m, t) =>
      `आपका मूलांक और भाग्यांक दोनों ${m} हैं, इसलिए इस अंक के गुण आपके जीवन में दोगुने हो जाते हैं। अंक ज्योतिष बताती है कि ${t.driver} आपके लगभग हर काम में दिखाई देता है और आपके जीवन की दिशा भी ${t.conductor} की ओर रहती है। इससे आप स्थिर और स्पष्ट पहचान वाले बनते हैं, पर दूसरे अंक से मिलने वाला स्वाभाविक संतुलन नहीं मिलता - ${m} की खूबियाँ और कठिनाइयाँ दोनों बढ़ जाती हैं।`,
    mixed: (m, b, mt, bt) =>
      `आपका मूलांक ${m} आपको ${mt.driver} देता है। आपका भाग्यांक ${b} आपके जीवन की दिशा तय करता है, जो ${bt.conductor} की ओर जाती है। अंक ज्योतिष के अनुसार आपका दैनिक स्वभाव ${m} से आता है, जबकि अवसर और लंबी राह ${b} से बनती है। जब ये दोनों साथ चलते हैं तो प्रगति स्थिर रहती है; जब आप किसी एक को अनदेखा करते हैं तो मेहनत के बावजूद परिणाम कम लगते हैं।`,
    personality: (mt, bt) =>
      `रोजमर्रा के व्यवहार में आपमें ${mt.driver} दिखता है। इसके भीतर आपके निर्णय आपको लगातार ${bt.conductor} की ओर ले जाते हैं। लोग पहली बात जल्दी पहचान लेते हैं और दूसरी बात आपको जानने के बाद ही समझ पाते हैं।`,
    career: (mt, bt) =>
      `ऐसा काम आपके लिए सबसे उपयुक्त है जिसमें ${mt.driver} का उपयोग हो और दिशा ${bt.conductor} की ओर बढ़े। केवल एक पक्ष का उपयोग करने वाली नौकरी कुछ वर्षों बाद अधूरी लगने लगती है।`,
    relationships: (mt, bt) =>
      `रिश्तों में आप ${mt.driver} लेकर आते हैं। पर साथी से आपको वास्तव में ${bt.conductor} के लिए सहयोग चाहिए। इसे खुलकर कह देने से इस संयोजन से जुड़ी अधिकतर खटपट टल जाती है।`,
    recommendations: (mt, bt) => `इस संयोजन के लिए परंपरागत सुझाव: ${mt.advice}; और ${bt.advice}।`,
    strengthLead: '',
    challengeLead: '',
  },
  mr: {
    title: (m, b, ml, bl) => `मूलांक ${m} आणि भाग्यांक ${b} - ${ml}, ${bl} च्या दिशेसह`,
    same: (m, t) =>
      `तुमचा मूलांक आणि भाग्यांक दोन्ही ${m} आहेत, त्यामुळे या अंकाचे गुण तुमच्या आयुष्यात दुप्पट होतात. अंकशास्त्र सुचवते की ${t.driver} तुमच्या जवळपास प्रत्येक कृतीत दिसतो आणि आयुष्याची दिशाही ${t.conductor} कडे राहते. यामुळे तुम्ही सातत्यपूर्ण आणि सहज ओळखू येणारे बनता, पण दुसऱ्या अंकाकडून मिळणारे नैसर्गिक संतुलन मिळत नाही - ${m} चे गुण आणि अडचणी दोन्ही वाढतात.`,
    mixed: (m, b, mt, bt) =>
      `तुमचा मूलांक ${m} तुम्हाला ${mt.driver} देतो. तुमचा भाग्यांक ${b} आयुष्याची दिशा ठरवतो, जी ${bt.conductor} कडे जाते. अंकशास्त्रानुसार तुमचा रोजचा स्वभाव ${m} मधून येतो, तर संधी आणि दीर्घ वाटचाल ${b} मधून घडते. हे दोन्ही एकत्र चालले की प्रगती स्थिर राहते; एकाकडे दुर्लक्ष केले की कष्ट होऊनही निकाल कमी वाटतात.`,
    personality: (mt, bt) =>
      `रोजच्या वागण्यात तुमच्यात ${mt.driver} दिसतो. त्याखाली तुमचे निर्णय तुम्हाला सतत ${bt.conductor} कडे नेतात. लोकांना पहिला गुण लगेच दिसतो आणि दुसरा तुम्हाला ओळखल्यावरच समजतो.`,
    career: (mt, bt) =>
      `ज्या कामात ${mt.driver} वापरता येईल आणि दिशा ${bt.conductor} कडे जाईल असे काम तुम्हाला सर्वात योग्य. केवळ एकाच बाजूचा वापर करणारी नोकरी काही वर्षांनी अपूर्ण वाटू लागते.`,
    relationships: (mt, bt) =>
      `नात्यांमध्ये तुम्ही ${mt.driver} घेऊन येता. पण जोडीदाराकडून तुम्हाला खरे तर ${bt.conductor} साठी पाठिंबा हवा असतो. हे स्पष्ट सांगितल्यास या संयोगाशी जोडलेले बहुतेक खटके टळतात.`,
    recommendations: (mt, bt) => `या संयोगासाठी पारंपरिक सूचना: ${mt.advice}; आणि ${bt.advice}.`,
    strengthLead: '',
    challengeLead: '',
  },
};

export interface CombinationSeed {
  mulank: number;
  bhagyank: number;
  locale: SeedLocale;
  title: string;
  description: string;
  personality: string;
  strengths: string[];
  challenges: string[];
  career: string;
  relationships: string;
  recommendations: string;
}

/** Picks up to `count` unique items, preferring items from the first list. */
function merge(a: string[], b: string[], count: number): string[] {
  const out: string[] = [];
  for (let i = 0; i < Math.max(a.length, b.length) && out.length < count; i += 1) {
    const first = a[i];
    const second = b[i];
    if (first && !out.includes(first)) out.push(first);
    if (out.length < count && second && !out.includes(second)) out.push(second);
  }
  return out;
}

/** Builds all 81 combinations for one locale. */
export function buildCombinations(locale: SeedLocale): CombinationSeed[] {
  const traits = TRAITS[locale];
  const template = TEMPLATES[locale];
  const rows: CombinationSeed[] = [];

  for (let mulank = 1; mulank <= 9; mulank += 1) {
    for (let bhagyank = 1; bhagyank <= 9; bhagyank += 1) {
      const mulankTrait = traits[mulank]!;
      const bhagyankTrait = traits[bhagyank]!;
      const mulankCopy = NUMBER_SEEDS.find((seed) => seed.number === mulank)!.copy[locale];
      const bhagyankCopy = NUMBER_SEEDS.find((seed) => seed.number === bhagyank)!.copy[locale];

      rows.push({
        mulank,
        bhagyank,
        locale,
        title: template.title(mulank, bhagyank, mulankTrait.label, bhagyankTrait.label),
        description:
          mulank === bhagyank
            ? template.same(mulank, mulankTrait)
            : template.mixed(mulank, bhagyank, mulankTrait, bhagyankTrait),
        personality: template.personality(mulankTrait, bhagyankTrait),
        strengths: merge(mulankCopy.strengths, bhagyankCopy.strengths, 6),
        challenges: merge(mulankCopy.weaknesses, bhagyankCopy.weaknesses, 5),
        career: template.career(mulankTrait, bhagyankTrait),
        relationships: template.relationships(mulankTrait, bhagyankTrait),
        recommendations: template.recommendations(mulankTrait, bhagyankTrait),
      });
    }
  }

  return rows;
}

export function buildAllCombinations(locales: SeedLocale[]): CombinationSeed[] {
  return locales.flatMap((locale) => buildCombinations(locale));
}
