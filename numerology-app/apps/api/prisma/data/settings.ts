import type { SeedLocale } from './numbers';

export interface AppSettingSeed {
  key: string;
  value: unknown;
  group: string;
  description: string;
  isPublic: boolean;
}

/**
 * Default application settings. Everything here is editable from
 * Admin -> Settings; the mobile app reads the public ones from
 * GET /api/v1/settings at startup and caches them.
 */
export const APP_SETTING_SEEDS: AppSettingSeed[] = [
  {
    key: 'app.name',
    value: { en: 'Ank Jyoti', hi: 'अंक ज्योति', mr: 'अंक ज्योती' },
    group: 'branding',
    description: 'Application name shown on the splash screen and in the app header.',
    isPublic: true,
  },
  {
    key: 'app.tagline',
    value: {
      en: 'Discover the numbers connected to you',
      hi: 'अपने अंकों को जानिए',
      mr: 'तुमच्याशी जोडलेले अंक जाणून घ्या',
    },
    group: 'branding',
    description: 'Tagline shown under the logo during onboarding.',
    isPublic: true,
  },
  {
    key: 'app.theme.colors',
    value: {
      primary: '#12203F',
      accent: '#C9A227',
      background: '#FBFAF7',
      surface: '#FFFFFF',
      text: '#1B1D22',
      muted: '#6B7280',
    },
    group: 'branding',
    description: 'Brand colours used by the mobile app. Changing these re-themes the app without a release.',
    isPublic: true,
  },
  {
    key: 'app.supportedLocales',
    value: ['en', 'hi', 'mr'],
    group: 'general',
    description: 'Locales offered in the language switcher.',
    isPublic: true,
  },
  {
    key: 'app.defaultLocale',
    value: 'en',
    group: 'general',
    description: 'Locale used when the device language is not supported.',
    isPublic: true,
  },
  {
    key: 'features',
    value: {
      coreNumbers: true,
      luckyNumber: true,
      nameNumerology: true,
      marriageCompatibility: true,
      history: true,
      favourites: true,
      sharing: true,
      notifications: false,
      kundaliReferral: true,
      monetisation: false,
    },
    group: 'features',
    description: 'Feature switches. A disabled feature is hidden in the app instead of showing a dead button.',
    isPublic: true,
  },
  {
    key: 'maintenance',
    value: {
      enabled: false,
      message: {
        en: 'We are carrying out scheduled maintenance. Please try again shortly.',
        hi: 'हम निर्धारित रखरखाव कर रहे हैं। कृपया थोड़ी देर बाद पुनः प्रयास करें।',
        mr: 'आम्ही नियोजित देखभाल करत आहोत. कृपया थोड्या वेळाने पुन्हा प्रयत्न करा.',
      },
    },
    group: 'general',
    description: 'When enabled the API returns 503 for user endpoints; the admin panel keeps working.',
    isPublic: true,
  },
  {
    key: 'home.welcome',
    value: {
      en: { morning: 'Good morning', afternoon: 'Good afternoon', evening: 'Good evening', fallback: 'Welcome' },
      hi: { morning: 'सुप्रभात', afternoon: 'नमस्कार', evening: 'शुभ संध्या', fallback: 'स्वागत है' },
      mr: { morning: 'सुप्रभात', afternoon: 'नमस्कार', evening: 'शुभ संध्याकाळ', fallback: 'स्वागत आहे' },
    },
    group: 'content',
    description: 'Greeting shown at the top of the home screen.',
    isPublic: true,
  },
  {
    key: 'marriage.scoreWeights',
    value: { mulankMatch: 50, bhagyankMatch: 35 },
    group: 'numerology',
    description:
      'Score awarded per matching direction. A Mulank match scores higher than a Bhagyank-only match; both directions matching gives the full score.',
    isPublic: false,
  },
  {
    key: 'marriage.kundaliReferral',
    value: {
      enabled: true,
      url: '',
      label: {
        en: 'Explore detailed Kundali analysis',
        hi: 'विस्तृत कुंडली विश्लेषण देखें',
        mr: 'सविस्तर कुंडली विश्लेषण पहा',
      },
      note: {
        en: 'This app does not perform Vedic Kundali calculations. This link opens information about consulting a qualified astrologer.',
        hi: 'यह ऐप वैदिक कुंडली गणना नहीं करता। यह लिंक योग्य ज्योतिषी से परामर्श की जानकारी दिखाता है।',
        mr: 'हे ॲप वैदिक कुंडली गणना करत नाही. हा दुवा पात्र ज्योतिषाकडून सल्ला घेण्याची माहिती दाखवतो.',
      },
    },
    group: 'content',
    description:
      'Referral shown after a compatibility result. It must never claim that the app itself performs Kundali matching.',
    isPublic: true,
  },
  {
    key: 'history.pageSize',
    value: 20,
    group: 'general',
    description: 'Default page size for calculation history.',
    isPublic: true,
  },
  {
    key: 'contact',
    value: { email: 'support@ankjyoti.app', phone: '', website: '' },
    group: 'content',
    description: 'Contact details shown on the About screen.',
    isPublic: true,
  },
];

interface LegalCopy {
  title: string;
  body: string;
}

const DISCLAIMER: Record<SeedLocale, LegalCopy> = {
  en: {
    title: 'Disclaimer',
    body: [
      'Numerology interpretations provided by this app are for informational and entertainment purposes. They should not be considered guaranteed predictions or professional medical, legal, financial, relationship or life advice.',
      '',
      'Numerology compatibility is only one interpretive method and should not be used as the sole basis for marriage or relationship decisions. Results are produced from the numerology rules configured in this application, not from scientific evidence.',
      '',
      'Always use your own judgement, and consult a qualified professional for medical, legal or financial matters.',
    ].join('\n'),
  },
  hi: {
    title: 'अस्वीकरण',
    body: [
      'इस ऐप में दी गई अंक ज्योतिष की व्याख्याएँ केवल जानकारी और मनोरंजन के लिए हैं। इन्हें निश्चित भविष्यवाणी या पेशेवर चिकित्सा, कानूनी, वित्तीय, रिश्तों या जीवन संबंधी सलाह न माना जाए।',
      '',
      'अंक ज्योतिष की अनुकूलता केवल एक व्याख्यात्मक पद्धति है और इसे विवाह या रिश्ते के निर्णय का एकमात्र आधार नहीं बनाया जाना चाहिए। परिणाम इस ऐप में सेट किए गए अंक ज्योतिष नियमों से आते हैं, किसी वैज्ञानिक प्रमाण से नहीं।',
      '',
      'सदैव अपने विवेक का उपयोग करें और चिकित्सा, कानूनी या वित्तीय मामलों में योग्य पेशेवर से परामर्श लें।',
    ].join('\n'),
  },
  mr: {
    title: 'अस्वीकरण',
    body: [
      'या ॲपमधील अंकशास्त्रीय विवेचन केवळ माहिती व मनोरंजनासाठी आहे. ते निश्चित भविष्यवाणी किंवा व्यावसायिक वैद्यकीय, कायदेशीर, आर्थिक, नातेसंबंध वा जीवनविषयक सल्ला मानू नये.',
      '',
      'अंकशास्त्रीय सुसंगतता ही केवळ एक विवेचन पद्धत आहे आणि विवाह किंवा नातेसंबंधाच्या निर्णयाचा एकमेव आधार म्हणून वापरू नये. निकाल या ॲपमध्ये निश्चित केलेल्या अंकशास्त्रीय नियमांवरून येतात, कोणत्याही वैज्ञानिक पुराव्यावरून नाही.',
      '',
      'नेहमी स्वतःचा विवेक वापरा आणि वैद्यकीय, कायदेशीर किंवा आर्थिक बाबींसाठी पात्र व्यावसायिकाचा सल्ला घ्या.',
    ].join('\n'),
  },
};

const PRIVACY: Record<SeedLocale, LegalCopy> = {
  en: {
    title: 'Privacy Policy',
    body: [
      'What we store: your date of birth (only if you choose to save it), your display name, the calculations you perform, and your app preferences.',
      '',
      'Guest use: you can use every core calculation without creating an account. Guest calculations are stored on your device unless you sign in.',
      '',
      'Analytics: usage events are recorded only after you allow analytics in Settings. We never record your date of birth or names inside analytics events.',
      '',
      'Your control: you can clear your calculation history at any time, and deleting your account removes your profile, history and saved results.',
      '',
      'Sharing: we do not sell personal data. Result cards you share contain only what you choose to include; your date of birth is hidden unless you turn it on.',
    ].join('\n'),
  },
  hi: {
    title: 'गोपनीयता नीति',
    body: [
      'हम क्या संग्रहित करते हैं: आपकी जन्म तिथि (केवल तभी जब आप उसे सहेजना चुनें), आपका नाम, आपके द्वारा की गई गणनाएँ और ऐप की सेटिंग्स।',
      '',
      'अतिथि उपयोग: आप बिना खाता बनाए सभी मुख्य गणनाएँ कर सकते हैं। साइन इन न करने पर अतिथि गणनाएँ आपके डिवाइस पर ही रहती हैं।',
      '',
      'एनालिटिक्स: उपयोग संबंधी घटनाएँ तभी दर्ज होती हैं जब आप सेटिंग्स में अनुमति देते हैं। एनालिटिक्स में आपकी जन्म तिथि या नाम कभी दर्ज नहीं किए जाते।',
      '',
      'आपका नियंत्रण: आप कभी भी अपना गणना इतिहास मिटा सकते हैं, और खाता हटाने पर आपकी प्रोफ़ाइल, इतिहास और सहेजे गए परिणाम हट जाते हैं।',
      '',
      'साझा करना: हम व्यक्तिगत डेटा नहीं बेचते। आप जो परिणाम कार्ड साझा करते हैं उनमें केवल वही होता है जो आप चुनते हैं; जन्म तिथि तब तक छिपी रहती है जब तक आप उसे दिखाना न चुनें।',
    ].join('\n'),
  },
  mr: {
    title: 'गोपनीयता धोरण',
    body: [
      'आम्ही काय साठवतो: तुमची जन्मतारीख (तुम्ही जतन करणे निवडल्यासच), तुमचे नाव, तुम्ही केलेली गणिते आणि ॲपची प्राधान्ये.',
      '',
      'पाहुणे वापर: खाते न बनवता तुम्ही सर्व मुख्य गणिते करू शकता. साइन इन केले नाही तर पाहुणे गणिते तुमच्या उपकरणावरच राहतात.',
      '',
      'विश्लेषण: वापराच्या नोंदी तुम्ही सेटिंग्जमध्ये परवानगी दिल्यावरच घेतल्या जातात. विश्लेषणात तुमची जन्मतारीख किंवा नावे कधीही नोंदवली जात नाहीत.',
      '',
      'तुमचे नियंत्रण: तुम्ही कधीही तुमचा गणना इतिहास पुसू शकता आणि खाते हटवल्यास तुमची प्रोफाइल, इतिहास व जतन केलेले निकाल काढून टाकले जातात.',
      '',
      'शेअरिंग: आम्ही वैयक्तिक माहिती विकत नाही. तुम्ही शेअर करता त्या निकाल कार्डवर तुम्ही निवडलेलेच दिसते; जन्मतारीख तुम्ही दाखवण्याचे ठरवेपर्यंत लपलेली राहते.',
    ].join('\n'),
  },
};

const TERMS: Record<SeedLocale, LegalCopy> = {
  en: {
    title: 'Terms & Conditions',
    body: [
      'By using this application you agree that numerology content is provided as guidance and interpretation, not as a guaranteed prediction of any future event.',
      '',
      'You are responsible for the decisions you take. The application, its authors and its operators are not liable for any loss arising from decisions based on the content shown here.',
      '',
      'You agree not to misuse the service, not to attempt unauthorised access, and not to submit another person\'s personal data without their consent.',
      '',
      'These terms may be updated. Continued use of the application after an update means you accept the revised terms.',
    ].join('\n'),
  },
  hi: {
    title: 'नियम एवं शर्तें',
    body: [
      'इस ऐप का उपयोग करके आप सहमत होते हैं कि अंक ज्योतिष की सामग्री मार्गदर्शन और व्याख्या के रूप में दी गई है, किसी भविष्य की घटना की गारंटी के रूप में नहीं।',
      '',
      'आपके निर्णयों की जिम्मेदारी आपकी है। यहाँ दी गई सामग्री के आधार पर लिए गए निर्णयों से होने वाली किसी हानि के लिए ऐप, इसके लेखक और संचालक उत्तरदायी नहीं हैं।',
      '',
      'आप सहमत हैं कि सेवा का दुरुपयोग नहीं करेंगे, अनधिकृत पहुँच का प्रयास नहीं करेंगे और किसी अन्य व्यक्ति का व्यक्तिगत डेटा उसकी सहमति के बिना दर्ज नहीं करेंगे।',
      '',
      'ये शर्तें बदली जा सकती हैं। अद्यतन के बाद ऐप का उपयोग जारी रखने का अर्थ है कि आप संशोधित शर्तें स्वीकार करते हैं।',
    ].join('\n'),
  },
  mr: {
    title: 'नियम व अटी',
    body: [
      'हे ॲप वापरून तुम्ही मान्य करता की अंकशास्त्रीय मजकूर मार्गदर्शन व विवेचन म्हणून दिला आहे, कोणत्याही भविष्यातील घटनेची हमी म्हणून नाही.',
      '',
      'तुमच्या निर्णयांची जबाबदारी तुमची आहे. येथे दाखवलेल्या मजकुरावर आधारित निर्णयांमुळे होणाऱ्या कोणत्याही नुकसानीस ॲप, त्याचे लेखक व संचालक जबाबदार नाहीत.',
      '',
      'तुम्ही सेवेचा गैरवापर करणार नाही, अनधिकृत प्रवेशाचा प्रयत्न करणार नाही आणि दुसऱ्या व्यक्तीची वैयक्तिक माहिती त्यांच्या संमतीशिवाय नोंदवणार नाही याला सहमती देता.',
      '',
      'या अटी बदलल्या जाऊ शकतात. बदलानंतर ॲप वापरणे सुरू ठेवणे म्हणजे सुधारित अटी स्वीकारणे होय.',
    ].join('\n'),
  },
};

const ABOUT: Record<SeedLocale, LegalCopy> = {
  en: {
    title: 'About Ank Jyoti',
    body: [
      'Ank Jyoti calculates Mulank (Driver Number) and Bhagyank (Conductor Number) from your date of birth using the Indian numerology system, and Chaldean values for name numerology.',
      '',
      'Everything the app shows - the interpretation of each number, the 81 Mulank and Bhagyank combinations, the compatibility rules and the Chaldean letter values - is stored as editable content, so the system can be corrected and improved without releasing a new app version.',
      '',
      'Marriage compatibility is checked in both directions, from each partner\'s Mulank towards the other partner\'s numbers, rather than assuming one person\'s number decides the result.',
    ].join('\n'),
  },
  hi: {
    title: 'अंक ज्योति के बारे में',
    body: [
      'अंक ज्योति आपकी जन्म तिथि से भारतीय अंक ज्योतिष पद्धति के अनुसार मूलांक (ड्राइवर नंबर) और भाग्यांक (कंडक्टर नंबर) निकालता है, तथा नाम अंक ज्योतिष के लिए कैल्डियन मान का उपयोग करता है।',
      '',
      'ऐप में दिखने वाली हर चीज़ - हर अंक की व्याख्या, मूलांक और भाग्यांक के 81 संयोजन, अनुकूलता नियम और कैल्डियन अक्षर मान - संपादन योग्य सामग्री के रूप में संग्रहित है, ताकि नया ऐप संस्करण जारी किए बिना सुधार किया जा सके।',
      '',
      'विवाह अनुकूलता दोनों दिशाओं में जाँची जाती है - प्रत्येक साथी के मूलांक से दूसरे साथी के अंकों की ओर - न कि यह मानकर कि किसी एक व्यक्ति का अंक ही परिणाम तय करता है।',
    ].join('\n'),
  },
  mr: {
    title: 'अंक ज्योती विषयी',
    body: [
      'अंक ज्योती तुमच्या जन्मतारखेवरून भारतीय अंकशास्त्र पद्धतीनुसार मूलांक (ड्रायव्हर नंबर) आणि भाग्यांक (कंडक्टर नंबर) काढते, तसेच नाव अंकशास्त्रासाठी कॅल्डियन मूल्ये वापरते.',
      '',
      'ॲपमध्ये दिसणारे सर्व काही - प्रत्येक अंकाचे विवेचन, मूलांक व भाग्यांकाचे 81 संयोग, सुसंगतता नियम आणि कॅल्डियन अक्षरमूल्ये - संपादन करता येणारा मजकूर म्हणून साठवलेले आहे, त्यामुळे नवीन ॲप आवृत्ती न काढता सुधारणा करता येते.',
      '',
      'विवाह सुसंगतता दोन्ही दिशांनी तपासली जाते - प्रत्येक जोडीदाराच्या मूलांकापासून दुसऱ्याच्या अंकांकडे - एकाच व्यक्तीचा अंक निकाल ठरवतो असे गृहीत न धरता.',
    ].join('\n'),
  },
};

export const LEGAL_SEEDS = { DISCLAIMER, PRIVACY, TERMS, ABOUT };
