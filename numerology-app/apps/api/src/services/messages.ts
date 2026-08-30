import type { CompatibilityReason, Locale, MatchLevel } from '@numerology/core';

/**
 * Localised sentences for calculated results.
 *
 * The engine returns machine readable codes; the wording lives here so the API
 * can answer in English, Hindi or Marathi from one calculation. The language
 * is deliberately plain and never states a result as a guaranteed prediction.
 */

type Params = Record<string, string | number>;

function interpolate(template: string, params: Params): string {
  return template.replace(/\{(\w+)\}/g, (_match, key: string) => String(params[key] ?? ''));
}

const VERDICT_LABEL: Record<Locale, Record<string, string>> = {
  en: { STRONG_MATCH: 'Strong Match', GOOD_MATCH: 'Good Match', NOT_MATCHED: 'Not Matched', NEUTRAL: 'Neutral', WEAK_MATCH: 'Weak Match' },
  hi: { STRONG_MATCH: 'मजबूत मेल', GOOD_MATCH: 'अच्छा मेल', NOT_MATCHED: 'मेल नहीं', NEUTRAL: 'सामान्य', WEAK_MATCH: 'कमजोर मेल' },
  mr: { STRONG_MATCH: 'मजबूत जुळणी', GOOD_MATCH: 'चांगली जुळणी', NOT_MATCHED: 'जुळणी नाही', NEUTRAL: 'सामान्य', WEAK_MATCH: 'कमकुवत जुळणी' },
};

const MARRIAGE_SUMMARY: Record<Locale, Record<string, string>> = {
  en: {
    STRONG_MATCH: 'Both directions match. Numerology suggests this pair supports each other naturally.',
    GOOD_MATCH: 'One direction matches. Numerology suggests a workable match that depends on understanding from both sides.',
    NOT_MATCHED: 'Based on the configured numerology compatibility rules, the numbers do not show a direct match.',
  },
  hi: {
    STRONG_MATCH: 'दोनों दिशाओं में मेल है। अंक ज्योतिष के अनुसार यह जोड़ी स्वाभाविक रूप से एक-दूसरे का साथ देती है।',
    GOOD_MATCH: 'एक दिशा में मेल है। अंक ज्योतिष के अनुसार यह मेल संभव है, पर दोनों ओर से समझदारी पर निर्भर करता है।',
    NOT_MATCHED: 'निर्धारित अंक ज्योतिष नियमों के आधार पर इन अंकों में सीधा मेल नहीं दिखता।',
  },
  mr: {
    STRONG_MATCH: 'दोन्ही दिशांनी जुळणी आहे. अंकशास्त्रानुसार ही जोडी एकमेकांना नैसर्गिकपणे साथ देते.',
    GOOD_MATCH: 'एका दिशेने जुळणी आहे. अंकशास्त्रानुसार ही जुळणी शक्य आहे, पण दोन्ही बाजूंच्या समजुतीवर अवलंबून आहे.',
    NOT_MATCHED: 'निश्चित केलेल्या अंकशास्त्रीय नियमांनुसार या अंकांमध्ये थेट जुळणी दिसत नाही.',
  },
};

const REASON_TEMPLATES: Record<Locale, Record<CompatibilityReason['code'], string>> = {
  en: {
    BOTH_DIRECTIONS:
      'Male Mulank {maleMulank} accepts the female numbers, and female Mulank {femaleMulank} also accepts the male numbers, so the match works in both directions.',
    MALE_TO_FEMALE_ONLY:
      'Male Mulank {maleMulank} is compatible with the female numbers, but female Mulank {femaleMulank} does not list the male numbers in its rule.',
    FEMALE_TO_MALE_ONLY:
      'Female Mulank {femaleMulank} is compatible with the male numbers, but male Mulank {maleMulank} does not list the female numbers in its rule.',
    NO_DIRECTION:
      'Neither Mulank {maleMulank} nor Mulank {femaleMulank} lists the other partner numbers in its rule.',
    RULE_MISSING: 'A compatibility rule has not been configured for one of these numbers yet.',
  },
  hi: {
    BOTH_DIRECTIONS:
      'पुरुष मूलांक {maleMulank} स्त्री के अंकों को स्वीकार करता है और स्त्री मूलांक {femaleMulank} भी पुरुष के अंकों को स्वीकार करता है, इसलिए मेल दोनों दिशाओं में बनता है।',
    MALE_TO_FEMALE_ONLY:
      'पुरुष मूलांक {maleMulank} स्त्री के अंकों के अनुकूल है, पर स्त्री मूलांक {femaleMulank} के नियम में पुरुष के अंक शामिल नहीं हैं।',
    FEMALE_TO_MALE_ONLY:
      'स्त्री मूलांक {femaleMulank} पुरुष के अंकों के अनुकूल है, पर पुरुष मूलांक {maleMulank} के नियम में स्त्री के अंक शामिल नहीं हैं।',
    NO_DIRECTION:
      'न मूलांक {maleMulank} के नियम में और न मूलांक {femaleMulank} के नियम में दूसरे साथी के अंक शामिल हैं।',
    RULE_MISSING: 'इनमें से किसी एक अंक के लिए अभी अनुकूलता नियम निर्धारित नहीं किया गया है।',
  },
  mr: {
    BOTH_DIRECTIONS:
      'पुरुष मूलांक {maleMulank} स्त्रीचे अंक स्वीकारतो आणि स्त्री मूलांक {femaleMulank} देखील पुरुषाचे अंक स्वीकारतो, त्यामुळे जुळणी दोन्ही दिशांनी होते.',
    MALE_TO_FEMALE_ONLY:
      'पुरुष मूलांक {maleMulank} स्त्रीच्या अंकांशी सुसंगत आहे, पण स्त्री मूलांक {femaleMulank} च्या नियमात पुरुषाचे अंक नाहीत.',
    FEMALE_TO_MALE_ONLY:
      'स्त्री मूलांक {femaleMulank} पुरुषाच्या अंकांशी सुसंगत आहे, पण पुरुष मूलांक {maleMulank} च्या नियमात स्त्रीचे अंक नाहीत.',
    NO_DIRECTION:
      'मूलांक {maleMulank} च्या नियमात किंवा मूलांक {femaleMulank} च्या नियमात दुसऱ्या जोडीदाराचे अंक नाहीत.',
    RULE_MISSING: 'यापैकी एका अंकासाठी अद्याप सुसंगतता नियम निश्चित केलेला नाही.',
  },
};

const VIA_NOTE: Record<Locale, Record<string, string>> = {
  en: {
    BHAGYANK: 'Compatibility found through the Bhagyank.',
    MULANK: 'Compatibility found through the Mulank.',
    BOTH: 'Compatibility found through both the Mulank and the Bhagyank.',
  },
  hi: {
    BHAGYANK: 'अनुकूलता भाग्यांक के माध्यम से मिली।',
    MULANK: 'अनुकूलता मूलांक के माध्यम से मिली।',
    BOTH: 'अनुकूलता मूलांक और भाग्यांक दोनों से मिली।',
  },
  mr: {
    BHAGYANK: 'सुसंगतता भाग्यांकाद्वारे आढळली.',
    MULANK: 'सुसंगतता मूलांकाद्वारे आढळली.',
    BOTH: 'सुसंगतता मूलांक आणि भाग्यांक दोन्हींद्वारे आढळली.',
  },
};

const NUMBER_MATCH_SUMMARY: Record<Locale, Record<MatchLevel, string>> = {
  en: {
    STRONG_MATCH: 'Your number has a strong connection with your own numbers.',
    GOOD_MATCH: 'Your number connects well with one of your numbers.',
    NEUTRAL: 'Your number is neutral for you - it neither supports nor works against your numbers.',
    WEAK_MATCH: 'Your number does not connect well with your numbers according to the configured rules.',
  },
  hi: {
    STRONG_MATCH: 'आपके इस नंबर का आपके अपने अंकों से मजबूत जुड़ाव है।',
    GOOD_MATCH: 'यह नंबर आपके एक अंक से अच्छा मेल रखता है।',
    NEUTRAL: 'यह नंबर आपके लिए सामान्य है - न विशेष लाभ, न बाधा।',
    WEAK_MATCH: 'निर्धारित नियमों के अनुसार यह नंबर आपके अंकों से अच्छा मेल नहीं रखता।',
  },
  mr: {
    STRONG_MATCH: 'या क्रमांकाचा तुमच्या अंकांशी मजबूत संबंध आहे.',
    GOOD_MATCH: 'हा क्रमांक तुमच्या एका अंकाशी चांगला जुळतो.',
    NEUTRAL: 'हा क्रमांक तुमच्यासाठी सामान्य आहे - विशेष फायदा नाही आणि अडथळाही नाही.',
    WEAK_MATCH: 'निश्चित नियमांनुसार हा क्रमांक तुमच्या अंकांशी चांगला जुळत नाही.',
  },
};

const AXIS_SENTENCE: Record<Locale, Record<MatchLevel, string>> = {
  en: {
    STRONG_MATCH: 'Number {root} supports your {axis} {value}.',
    GOOD_MATCH: 'Number {root} supports your {axis} {value}.',
    NEUTRAL: 'Number {root} is neutral for your {axis} {value}.',
    WEAK_MATCH: 'Number {root} is not favourable for your {axis} {value}.',
  },
  hi: {
    STRONG_MATCH: 'अंक {root} आपके {axis} {value} का साथ देता है।',
    GOOD_MATCH: 'अंक {root} आपके {axis} {value} का साथ देता है।',
    NEUTRAL: 'अंक {root} आपके {axis} {value} के लिए सामान्य है।',
    WEAK_MATCH: 'अंक {root} आपके {axis} {value} के लिए अनुकूल नहीं है।',
  },
  mr: {
    STRONG_MATCH: 'अंक {root} तुमच्या {axis} {value} ला साथ देतो.',
    GOOD_MATCH: 'अंक {root} तुमच्या {axis} {value} ला साथ देतो.',
    NEUTRAL: 'अंक {root} तुमच्या {axis} {value} साठी सामान्य आहे.',
    WEAK_MATCH: 'अंक {root} तुमच्या {axis} {value} साठी अनुकूल नाही.',
  },
};

const AXIS_LABEL: Record<Locale, Record<'MULANK' | 'BHAGYANK', string>> = {
  en: { MULANK: 'Mulank', BHAGYANK: 'Bhagyank' },
  hi: { MULANK: 'मूलांक', BHAGYANK: 'भाग्यांक' },
  mr: { MULANK: 'मूलांक', BHAGYANK: 'भाग्यांक' },
};

const NAME_COMPARISON: Record<Locale, Record<MatchLevel, string>> = {
  en: {
    STRONG_MATCH: 'Your name number works well with your {axis} {value}.',
    GOOD_MATCH: 'Your name number works well with your {axis} {value}.',
    NEUTRAL: 'Your name number is neutral against your {axis} {value}.',
    WEAK_MATCH: 'Your name number pulls in a different direction from your {axis} {value}.',
  },
  hi: {
    STRONG_MATCH: 'आपका नाम अंक आपके {axis} {value} के साथ अच्छा चलता है।',
    GOOD_MATCH: 'आपका नाम अंक आपके {axis} {value} के साथ अच्छा चलता है।',
    NEUTRAL: 'आपका नाम अंक आपके {axis} {value} के लिए सामान्य है।',
    WEAK_MATCH: 'आपका नाम अंक आपके {axis} {value} से अलग दिशा में जाता है।',
  },
  mr: {
    STRONG_MATCH: 'तुमचा नाव अंक तुमच्या {axis} {value} सोबत चांगला चालतो.',
    GOOD_MATCH: 'तुमचा नाव अंक तुमच्या {axis} {value} सोबत चांगला चालतो.',
    NEUTRAL: 'तुमचा नाव अंक तुमच्या {axis} {value} साठी सामान्य आहे.',
    WEAK_MATCH: 'तुमचा नाव अंक तुमच्या {axis} {value} पेक्षा वेगळ्या दिशेने जातो.',
  },
};

const MISSING_DOB: Record<Locale, string> = {
  en: 'Add your date of birth to personalise this calculation.',
  hi: 'इस गणना को व्यक्तिगत बनाने के लिए अपनी जन्म तिथि जोड़ें।',
  mr: 'ही गणना वैयक्तिक करण्यासाठी तुमची जन्मतारीख जोडा.',
};

const DISCLAIMERS: Record<Locale, { general: string; marriage: string; kundali: string }> = {
  en: {
    general:
      'Numerology interpretations are for informational and entertainment purposes and are not guaranteed predictions.',
    marriage:
      'Numerology compatibility is only one interpretive method and should not be used as the sole basis for marriage or relationship decisions.',
    kundali:
      'For a detailed traditional assessment you may consider a complete Kundali analysis with a qualified astrologer. This app does not perform Vedic Kundali calculations.',
  },
  hi: {
    general:
      'अंक ज्योतिष की व्याख्याएँ केवल जानकारी और मनोरंजन के लिए हैं और ये निश्चित भविष्यवाणी नहीं हैं।',
    marriage:
      'अंक ज्योतिष की अनुकूलता केवल एक व्याख्यात्मक पद्धति है और इसे विवाह या रिश्ते के निर्णय का एकमात्र आधार नहीं बनाना चाहिए।',
    kundali:
      'विस्तृत पारंपरिक आकलन के लिए आप किसी योग्य ज्योतिषी से पूर्ण कुंडली विश्लेषण करा सकते हैं। यह ऐप वैदिक कुंडली गणना नहीं करता।',
  },
  mr: {
    general:
      'अंकशास्त्रीय विवेचन केवळ माहिती व मनोरंजनासाठी आहे आणि ती निश्चित भविष्यवाणी नाही.',
    marriage:
      'अंकशास्त्रीय सुसंगतता ही केवळ एक विवेचन पद्धत आहे आणि विवाह किंवा नातेसंबंधाच्या निर्णयाचा एकमेव आधार म्हणून वापरू नये.',
    kundali:
      'सविस्तर पारंपरिक मूल्यांकनासाठी तुम्ही पात्र ज्योतिषाकडून संपूर्ण कुंडली विश्लेषण करून घेऊ शकता. हे ॲप वैदिक कुंडली गणना करत नाही.',
  },
};

export const messages = {
  verdictLabel: (locale: Locale, verdict: string) => VERDICT_LABEL[locale][verdict] ?? verdict,
  marriageSummary: (locale: Locale, verdict: string) => MARRIAGE_SUMMARY[locale][verdict] ?? '',
  reason: (locale: Locale, reason: CompatibilityReason) =>
    interpolate(REASON_TEMPLATES[locale][reason.code], reason.params),
  viaNote: (locale: Locale, via: string) => VIA_NOTE[locale][via] ?? null,
  numberMatchSummary: (locale: Locale, level: MatchLevel) => NUMBER_MATCH_SUMMARY[locale][level],
  axisSentence: (locale: Locale, level: MatchLevel, axis: 'MULANK' | 'BHAGYANK', root: number, value: number) =>
    interpolate(AXIS_SENTENCE[locale][level], { root, axis: AXIS_LABEL[locale][axis], value }),
  nameComparison: (locale: Locale, level: MatchLevel, axis: 'MULANK' | 'BHAGYANK', value: number) =>
    interpolate(NAME_COMPARISON[locale][level], { axis: AXIS_LABEL[locale][axis], value }),
  axisLabel: (locale: Locale, axis: 'MULANK' | 'BHAGYANK') => AXIS_LABEL[locale][axis],
  missingDob: (locale: Locale) => MISSING_DOB[locale],
  disclaimers: (locale: Locale) => DISCLAIMERS[locale],
};
