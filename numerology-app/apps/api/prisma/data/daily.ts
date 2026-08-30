import type { SeedLocale } from './numbers';

/** Short interpretation shown under Today's Lucky Number on the home screen. */
export interface DailyInsightSeed {
  number: number;
  locale: SeedLocale;
  title: string;
  message: string;
}

const DAILY: Record<SeedLocale, Record<number, { title: string; message: string }>> = {
  en: {
    1: { title: 'A day to begin', message: 'Today is traditionally associated with initiative. A good day to start something you have been postponing, or to take a decision on your own instead of waiting for agreement.' },
    2: { title: 'A day for people', message: 'Today favours conversation and cooperation. Numerology suggests handling sensitive matters gently and listening more than usual.' },
    3: { title: 'A day to learn and share', message: 'Today is associated with knowledge and guidance. Good for study, teaching, paperwork and honest advice. Avoid over-promising.' },
    4: { title: 'A day for practical work', message: 'Today suits detailed, technical or pending work. Numerology suggests double-checking documents and avoiding hasty commitments.' },
    5: { title: 'A day for connections', message: 'Today favours communication, travel, meetings and business talk. A good day to follow up on something that stalled.' },
    6: { title: 'A day for family and comfort', message: 'Today is associated with relationships, home and beauty. Good for family matters, shopping for the home, or repairing a small misunderstanding.' },
    7: { title: 'A day to think it through', message: 'Today favours research, reflection and quiet work. Numerology suggests postponing an emotional decision until you have slept on it.' },
    8: { title: 'A day for discipline', message: 'Today is associated with steady effort and financial matters. Progress may feel slow, but work done today tends to last.' },
    9: { title: 'A day for action', message: 'Today carries high energy. Good for finishing pending tasks and physical activity. Numerology suggests keeping your temper in check during discussions.' },
  },
  hi: {
    1: { title: 'शुरुआत का दिन', message: 'आज का दिन परंपरागत रूप से पहल से जुड़ा है। जिस काम को टाल रहे थे उसे शुरू करने या सहमति की प्रतीक्षा किए बिना निर्णय लेने के लिए अच्छा दिन।' },
    2: { title: 'लोगों का दिन', message: 'आज बातचीत और सहयोग के लिए अनुकूल है। अंक ज्योतिष सुझाती है कि संवेदनशील मामलों को नरमी से संभालें और सामान्य से अधिक सुनें।' },
    3: { title: 'सीखने और सिखाने का दिन', message: 'आज का दिन ज्ञान और मार्गदर्शन से जुड़ा है। अध्ययन, शिक्षण, कागजी काम और ईमानदार सलाह के लिए अच्छा। जरूरत से ज्यादा वादे न करें।' },
    4: { title: 'व्यावहारिक काम का दिन', message: 'आज बारीक, तकनीकी या रुके हुए कामों के लिए उपयुक्त है। दस्तावेज दोबारा जाँच लें और जल्दबाजी में वचन न दें।' },
    5: { title: 'संपर्कों का दिन', message: 'आज संवाद, यात्रा, बैठकों और व्यापारिक बातचीत के लिए अनुकूल है। रुके हुए काम पर फिर से संपर्क करने का अच्छा दिन।' },
    6: { title: 'परिवार और सुख का दिन', message: 'आज का दिन रिश्तों, घर और सौंदर्य से जुड़ा है। पारिवारिक कामों, घर की खरीदारी या छोटी गलतफहमी सुलझाने के लिए अच्छा।' },
    7: { title: 'सोच-विचार का दिन', message: 'आज अनुसंधान, चिंतन और शांत काम के लिए अनुकूल है। भावनात्मक निर्णय एक रात सोचने के बाद ही लें।' },
    8: { title: 'अनुशासन का दिन', message: 'आज का दिन निरंतर परिश्रम और आर्थिक मामलों से जुड़ा है। प्रगति धीमी लग सकती है, पर आज किया गया काम टिकाऊ होता है।' },
    9: { title: 'कर्म का दिन', message: 'आज ऊर्जा अधिक है। रुके हुए काम पूरे करने और शारीरिक गतिविधि के लिए अच्छा। चर्चा के दौरान गुस्से पर नियंत्रण रखें।' },
  },
  mr: {
    1: { title: 'सुरुवातीचा दिवस', message: 'आजचा दिवस पारंपरिकपणे पुढाकाराशी जोडलेला आहे. लांबणीवर टाकलेले काम सुरू करण्यासाठी किंवा संमतीची वाट न पाहता निर्णय घेण्यासाठी चांगला दिवस.' },
    2: { title: 'माणसांचा दिवस', message: 'आज संवाद आणि सहकार्यासाठी अनुकूल आहे. संवेदनशील विषय मृदूपणे हाताळा आणि नेहमीपेक्षा जास्त ऐका.' },
    3: { title: 'शिकण्या-शिकवण्याचा दिवस', message: 'आजचा दिवस ज्ञान व मार्गदर्शनाशी जोडलेला आहे. अभ्यास, शिकवणे, कागदपत्रे आणि प्रामाणिक सल्ल्यासाठी चांगला. जास्त वचने देऊ नका.' },
    4: { title: 'व्यावहारिक कामाचा दिवस', message: 'आज बारकाईचे, तांत्रिक किंवा प्रलंबित कामांसाठी योग्य. कागदपत्रे पुन्हा तपासा आणि घाईने वचन देऊ नका.' },
    5: { title: 'संपर्कांचा दिवस', message: 'आज संवाद, प्रवास, बैठका आणि व्यावसायिक बोलणीसाठी अनुकूल. थांबलेल्या कामाचा पाठपुरावा करण्यासाठी चांगला दिवस.' },
    6: { title: 'कुटुंब व सुखाचा दिवस', message: 'आजचा दिवस नाती, घर आणि सौंदर्याशी जोडलेला आहे. कौटुंबिक कामे, घरासाठी खरेदी किंवा छोटा गैरसमज दूर करण्यासाठी चांगला.' },
    7: { title: 'विचार करण्याचा दिवस', message: 'आज संशोधन, चिंतन आणि शांत कामासाठी अनुकूल. भावनिक निर्णय एक रात्र विचार केल्यावरच घ्या.' },
    8: { title: 'शिस्तीचा दिवस', message: 'आजचा दिवस सातत्यपूर्ण कष्ट आणि आर्थिक बाबींशी जोडलेला आहे. प्रगती संथ वाटेल, पण आज केलेले काम टिकाऊ ठरते.' },
    9: { title: 'कृतीचा दिवस', message: 'आज ऊर्जा जास्त आहे. प्रलंबित कामे पूर्ण करण्यासाठी आणि शारीरिक हालचालीसाठी चांगला. चर्चेत रागावर नियंत्रण ठेवा.' },
  },
};

export function buildDailyInsights(locales: SeedLocale[]): DailyInsightSeed[] {
  return locales.flatMap((locale) =>
    Object.entries(DAILY[locale]).map(([number, copy]) => ({
      number: Number(number),
      locale,
      title: copy.title,
      message: copy.message,
    })),
  );
}
