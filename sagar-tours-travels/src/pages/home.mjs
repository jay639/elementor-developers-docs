/** Home page — assembled in the order a visitor needs it:
 *  land → understand → trust → choose a service → see vehicles → get a fare → book. */
import { html } from '../lib/html.mjs';
import { Layout, faqSchema } from '../components/Layout.mjs';
import { Hero } from '../components/Hero.mjs';
import { TrustStats } from '../components/TrustStats.mjs';
import { ServicesSection } from '../components/ServiceCard.mjs';
import { WhyChooseUs } from '../components/BenefitItem.mjs';
import { FleetSection } from '../components/FleetCard.mjs';
import { RoutesSection } from '../components/RouteCard.mjs';
import { DestinationsSection } from '../components/DestinationCard.mjs';
import { HowItWorks } from '../components/HowItWorks.mjs';
import { About } from '../components/About.mjs';
import { ReviewsSection } from '../components/ReviewCard.mjs';
import { FAQSection } from '../components/FAQAccordion.mjs';
import { CTASection } from '../components/CTASection.mjs';
import { ContactSection } from '../components/ContactCard.mjs';
import { site } from '../data/site.mjs';

export function HomePage() {
  return Layout({
    title: site.seo.title,
    description: site.seo.description,
    path: '/',
    schema: [faqSchema()],
    children: html`${Hero()} ${TrustStats()} ${ServicesSection()} ${WhyChooseUs()} ${FleetSection()}
    ${RoutesSection()} ${DestinationsSection()} ${HowItWorks()} ${About()} ${ReviewsSection()}
    ${FAQSection()} ${CTASection()} ${ContactSection()}`,
  });
}
