import { useEffect, useState, type FormEvent } from 'react';
import { Link, Navigate, Route, Routes, useNavigate, useParams, useSearchParams } from 'react-router-dom';
import type { EmiPlan, Product, ProductSummary, Variant } from './types';

const rupees = (paise: number) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(paise / 100);
const rate = (basisPoints: number) => basisPoints === 0 ? '0% interest' : `${(basisPoints / 100).toFixed(1)}% interest`;

function SiteHeader() {
  return <header className="site-header">
    <div className="nav-shell">
      <Link className="brand" to="/" aria-label="FlexiPay home"><span>flexi</span>pay</Link>
      <nav className="site-nav" aria-label="Main navigation">
        <Link to="/">Shop phones</Link>
        <Link to="/#how-it-works">How it works</Link>
        <a href="mailto:support@flexipay.example">Support</a>
      </nav>
      <Link className="nav-cta" to="/">Explore plans</Link>
    </div>
  </header>;
}

function SiteFooter() {
  return <footer className="site-footer">
    <div className="footer-shell">
      <div className="footer-intro"><Link className="brand" to="/"><span>flexi</span>pay</Link><p>Smarter ways to bring home the technology you love.</p></div>
      <div className="footer-links"><div><h2>Explore</h2><Link to="/">All phones</Link><Link to="/#how-it-works">How it works</Link></div><div><h2>Support</h2><a href="mailto:support@flexipay.example">Contact us</a><a href="mailto:help@flexipay.example">Help centre</a></div><div><h2>Legal</h2><a href="#terms">Terms of use</a><a href="#privacy">Privacy policy</a></div></div>
    </div>
    <div className="footer-bottom"><span>© 2026 FlexiPay. Demo storefront.</span><span>EMI plans backed by mutual funds</span></div>
  </footer>;
}

function Catalog() {
  const [products, setProducts] = useState<ProductSummary[]>([]);
  const [error, setError] = useState('');
  useEffect(() => { fetch('/api/products').then(r => r.ok ? r.json() : Promise.reject()).then(setProducts).catch(() => setError('Catalog data is currently unavailable.')); }, []);
  if (error) return <main className="status">{error}</main>;
  return <main className="catalog-page">
    <section className="catalog-intro"><span className="eyebrow">FLEXIPAY STORE</span><h1>Choose a phone.<br />Choose your pace.</h1><p>Explore zero-interest EMI plans backed by mutual funds.</p></section>
    <section className="catalog-grid" aria-label="Available products">
      {products.length === 0 ? <p className="status">Loading products…</p> : products.map(product => <Link className="catalog-card" to={`/products/${product.slug}`} key={product.id} aria-label={`View EMI plans for ${product.name}`}>
        <img src={product.imageUrl} alt="" /><div><span>{product.defaultStorage}</span><h2>{product.name}</h2><p>{rupees(product.pricePaise)}</p><span className="catalog-link">View EMI plans <b>→</b></span></div>
      </Link>)}
    </section>
    <section className="how-it-works" id="how-it-works"><span className="eyebrow">HOW FLEXIPAY WORKS</span><h2>Pick a plan that fits your month.</h2><div className="steps"><p><b>01</b> Choose your phone and finish.</p><p><b>02</b> Compare clear, upfront EMI plans.</p><p><b>03</b> Continue with the plan that feels right.</p></div></section>
  </main>;
}

function PlanCard({ plan, selected, onSelect }: { plan: EmiPlan; selected: boolean; onSelect: () => void }) {
  return <button type="button" className={`plan-card ${selected ? 'selected' : ''}`} onClick={onSelect} aria-pressed={selected}>
    <span className="plan-main">{rupees(plan.monthlyPaymentPaise)} <small>× {plan.tenureMonths} months</small></span><span className="plan-rate"><strong>{rate(plan.interestRateBps)}</strong>{selected && <span className="selected-tag">Selected</span>}</span>
    {plan.cashbackPaise > 0 && <span className="cashback">Additional cashback of {rupees(plan.cashbackPaise)}</span>}
  </button>;
}

function ProductPage() {
  const { slug } = useParams();
  const [product, setProduct] = useState<Product | null>(null);
  const [variant, setVariant] = useState<Variant | null>(null);
  const [selectedPlan, setSelectedPlan] = useState<EmiPlan | null>(null);
  const [error, setError] = useState('');
  const navigate = useNavigate();
  useEffect(() => {
    setProduct(null); setVariant(null); setSelectedPlan(null); setError('');
    fetch(`/api/products/${slug}`).then(async response => {
      if (response.status === 404) throw new Error('This product could not be found.');
      if (!response.ok) throw new Error('Product data is currently unavailable.');
      return response.json();
    }).then((data: Product) => { const initialVariant = data.variants[0] ?? null; setProduct(data); setVariant(initialVariant); setSelectedPlan(data.plans.find(plan => plan.variantId === initialVariant?.id) ?? null); }).catch((e: Error) => setError(e.message));
  }, [slug]);
  if (error) return <main className="status"><p>{error}</p><Link to="/">Back to catalog</Link></main>;
  if (!product || !variant || !selectedPlan) return <main className="status">Loading product and EMI plans…</main>;
  const configurationOptions = product.variants.filter((item, index, variants) => variants.findIndex(candidate => candidate.ram === item.ram && candidate.storage === item.storage) === index);
  const finishOptions = product.variants.filter((item, index, variants) => item.storage === variant.storage && item.ram === variant.ram && variants.findIndex(candidate => candidate.label === item.label && candidate.storage === item.storage && candidate.ram === item.ram) === index);
  const selectConfiguration = (configuration: Variant) => {
    const matchingFinish = product.variants.find(item => item.ram === configuration.ram && item.storage === configuration.storage && item.label === variant.label);
    const nextVariant = matchingFinish ?? configuration;
    setVariant(nextVariant);
    setSelectedPlan(product.plans.find(plan => plan.variantId === nextVariant.id && plan.tenureMonths === selectedPlan.tenureMonths) ?? product.plans.find(plan => plan.variantId === nextVariant.id) ?? null);
  };
  const selectFinish = (nextVariant: Variant) => { setVariant(nextVariant); setSelectedPlan(product.plans.find(plan => plan.variantId === nextVariant.id && plan.tenureMonths === selectedPlan.tenureMonths) ?? product.plans.find(plan => plan.variantId === nextVariant.id) ?? null); };
  const availablePlans = product.plans.filter(plan => plan.variantId === variant.id);
  return <main className="product-page">
    <div className="breadcrumb"><Link to="/">← All phones</Link><span>Choose your plan</span></div>
    <div className="detail-grid">
      <section className="product-card">
        <div className="product-copy"><span className="new">NEW</span><h1>{product.name}</h1><p>{variant.ram} RAM · {variant.storage} · {variant.label}</p></div>
        <img className="product-image" src={variant.imageUrl || product.imageUrl} alt={`${product.name} in ${variant.label}`} />
        <section className="specifications" aria-label={`${product.name} specifications`}><p>Key specifications</p><dl>{product.specifications.map(specification => <div key={specification.id}><dt>{specification.label}</dt><dd>{specification.value}</dd></div>)}</dl></section>
        <div className="variant-pickers">
          <div className="storage-picker"><p>RAM + storage</p><div role="radiogroup" aria-label="Choose RAM and storage">{configurationOptions.map(configuration => <button type="button" key={`${configuration.ram}-${configuration.storage}`} className={configuration.ram === variant.ram && configuration.storage === variant.storage ? 'storage-option active' : 'storage-option'} onClick={() => selectConfiguration(configuration)} role="radio" aria-checked={configuration.ram === variant.ram && configuration.storage === variant.storage}>{configuration.ram} + {configuration.storage}</button>)}</div></div>
          <div className="finish-picker"><p>Finish · {variant.label}</p><div role="radiogroup" aria-label="Choose finish">{finishOptions.map(item => <button type="button" key={item.id} className={item.id === variant.id ? 'finish active' : 'finish'} style={{ backgroundColor: item.colorHex }} onClick={() => selectFinish(item)} aria-label={item.label} role="radio" aria-checked={item.id === variant.id} />)}</div></div>
        </div>
      </section>
      <section className="plans-panel">
        <header><p className="price">{rupees(variant.pricePaise)}</p><p className="mrp">{rupees(variant.mrpPaise)}</p><h2>EMI plans backed by mutual funds</h2></header>
        <div className="plan-list">{availablePlans.map(plan => <PlanCard plan={plan} key={plan.id} selected={selectedPlan.id === plan.id} onSelect={() => setSelectedPlan(plan)} />)}</div>
        <button className="proceed-button" type="button" onClick={() => navigate(`/checkout?product=${product.slug}&variant=${variant.id}&plan=${selectedPlan.id}`)}>Proceed to checkout <span>→</span></button>
      </section>
    </div>
  </main>;
}

function CheckoutPage() {
  const [searchParams] = useSearchParams();
  const productSlug = searchParams.get('product');
  const variantId = Number(searchParams.get('variant'));
  const planId = Number(searchParams.get('plan'));
  const [product, setProduct] = useState<Product | null>(null);
  const [error, setError] = useState('');
  const [complete, setComplete] = useState(false);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  useEffect(() => {
    if (!productSlug || !variantId || !planId) return;
    fetch(`/api/products/${productSlug}`).then(response => response.ok ? response.json() : Promise.reject()).then((data: Product) => setProduct(data)).catch(() => setError('Checkout details are currently unavailable.'));
  }, [productSlug, variantId, planId]);
  if (complete) return <main className="commerce-page"><section className="confirmation"><span className="eyebrow">ORDER RECEIVED</span><h1>Your plan is reserved.</h1><p>We’ve recorded your selected EMI plans. A representative will contact you to complete the application.</p><Link className="proceed-button" to="/">Continue shopping <span>→</span></Link></section></main>;
  if (!productSlug || !variantId || !planId) return <Navigate to="/" replace />;
  if (error) return <main className="status"><p>{error}</p><Link to="/">Back to catalog</Link></main>;
  if (!product) return <main className="status">Loading checkout details…</main>;
  const variant = product.variants.find(item => item.id === variantId);
  const plan = product.plans.find(item => item.id === planId);
  if (!variant || !plan) return <Navigate to={`/products/${product.slug}`} replace />;
  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const values = new FormData(event.currentTarget);
    const name = String(values.get('name') ?? '').trim();
    const email = String(values.get('email') ?? '').trim();
    const phone = String(values.get('phone') ?? '').replace(/\D/g, '');
    const city = String(values.get('city') ?? '').trim();
    const errors: Record<string, string> = {};
    if (!/^[A-Za-z][A-Za-z .'-]{1,}$/.test(name)) errors.name = 'Enter your full name (at least 2 characters).';
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email)) errors.email = 'Enter a valid email address.';
    if (!/^[6-9]\d{9}$/.test(phone)) errors.phone = 'Enter a valid 10-digit Indian mobile number.';
    if (!/^[A-Za-z][A-Za-z .'-]{1,}$/.test(city)) errors.city = 'Enter a valid delivery city.';
    setFieldErrors(errors);
    if (Object.keys(errors).length) { event.currentTarget.querySelector<HTMLElement>('[aria-invalid="true"]')?.focus(); return; }
    setComplete(true);
  };
  const clearFieldError = (field: string) => setFieldErrors(current => { const { [field]: _removed, ...rest } = current; return rest; });
  return <main className="commerce-page"><div className="commerce-heading"><span className="eyebrow">SECURE CHECKOUT</span><h1>Almost there.</h1><p>Share your details to continue with your selected plan.</p></div><div className="checkout-layout"><form className="checkout-form" noValidate onSubmit={submit}><h2>Contact details</h2><label>Full name<input aria-invalid={Boolean(fieldErrors.name)} aria-describedby={fieldErrors.name ? 'name-error' : undefined} name="name" autoComplete="name" placeholder="Your full name" onChange={() => clearFieldError('name')} />{fieldErrors.name && <small id="name-error" className="field-error">{fieldErrors.name}</small>}</label><label>Email address<input aria-invalid={Boolean(fieldErrors.email)} aria-describedby={fieldErrors.email ? 'email-error' : undefined} type="email" name="email" autoComplete="email" placeholder="you@example.com" onChange={() => clearFieldError('email')} />{fieldErrors.email && <small id="email-error" className="field-error">{fieldErrors.email}</small>}</label><label>Mobile number<input aria-invalid={Boolean(fieldErrors.phone)} aria-describedby={fieldErrors.phone ? 'phone-error' : undefined} type="tel" name="phone" inputMode="numeric" autoComplete="tel" placeholder="10-digit mobile number" onChange={() => clearFieldError('phone')} />{fieldErrors.phone && <small id="phone-error" className="field-error">{fieldErrors.phone}</small>}</label><label>Delivery city<input aria-invalid={Boolean(fieldErrors.city)} aria-describedby={fieldErrors.city ? 'city-error' : undefined} name="city" autoComplete="address-level2" placeholder="City" onChange={() => clearFieldError('city')} />{fieldErrors.city && <small id="city-error" className="field-error">{fieldErrors.city}</small>}</label><button className="proceed-button" type="submit">Place demo order <span>→</span></button><p className="summary-note">By continuing, you agree to be contacted about your EMI application.</p></form><aside className="order-summary checkout-summary"><p className="eyebrow">YOUR SELECTED PLAN</p><div className="summary-product"><span>{product.name}</span><strong>{rupees(plan.monthlyPaymentPaise)}/mo</strong><small>{variant.ram} RAM · {variant.storage} · {variant.label} · {plan.tenureMonths} months</small></div><div><span>Interest rate</span><strong>{rate(plan.interestRateBps)}</strong></div>{plan.cashbackPaise > 0 && <div className="summary-cashback"><span>Potential cashback</span><strong>{rupees(plan.cashbackPaise)}</strong></div>}<div><span>Monthly commitment</span><strong>{rupees(plan.monthlyPaymentPaise)}</strong></div></aside></div></main>;
}

export default function App() { return <div className="site-shell"><style>{`.plan-card.selected { box-shadow: 0 5px 16px #008a6026; } .catalog-intro { margin-inline: auto; text-align: center; }`}</style><SiteHeader /><Routes><Route path="/" element={<Catalog />} /><Route path="/products/:slug" element={<ProductPage />} /><Route path="/checkout" element={<CheckoutPage />} /><Route path="*" element={<Navigate to="/" replace />} /></Routes><SiteFooter /></div>; }
