import { useEffect, useLayoutEffect, useState, type FormEvent } from 'react';
import { Link, Navigate, Route, Routes, useLocation, useNavigate, useParams, useSearchParams } from 'react-router-dom';
import type { Category, EmiPlan, Product, ProductSummary, Variant } from './types';

const rupees = (paise: number) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(paise / 100);
const rate = (basisPoints: number) => basisPoints === 0 ? '0% interest' : `${(basisPoints / 100).toFixed(1)}% interest`;
const apiBaseUrl = (import.meta.env.VITE_API_BASE_URL ?? '').replace(/\/+$/, '');
const apiUrl = (path: string) => `${apiBaseUrl}${path}`;

function ScrollManager() {
  const { pathname, search, hash } = useLocation();
  useEffect(() => {
    const previous = window.history.scrollRestoration;
    window.history.scrollRestoration = 'manual';
    return () => { window.history.scrollRestoration = previous; };
  }, []);
  useLayoutEffect(() => {
    if (hash) {
      const id = decodeURIComponent(hash.slice(1));
      requestAnimationFrame(() => document.getElementById(id)?.scrollIntoView({ block: 'start' }));
      return;
    }
    const resetScroll = () => window.scrollTo({ top: 0, left: 0, behavior: 'auto' });
    resetScroll();
    const animationFrame = requestAnimationFrame(resetScroll);
    return () => cancelAnimationFrame(animationFrame);
  }, [pathname, search, hash]);
  return null;
}

function SiteHeader() {
  return <header className="site-header sticky top-0 z-20">
    <div className="nav-shell mx-auto flex items-center justify-between">
      <Link className="brand" to="/" aria-label="FlexiPay home"><span>flexi</span>pay</Link>
      <nav className="site-nav" aria-label="Main navigation">
        <a href="/#catalog">Shop electronics</a>
        <a href="/#how-it-works">How it works</a>
        <a href="/#support">Support</a>
      </nav>
      <a className="nav-cta" href="/#plans">Explore plans</a>
    </div>
  </header>;
}

function SiteFooter() {
  return <footer className="site-footer">
    <div className="footer-shell">
      <div className="footer-intro"><Link className="brand" to="/"><span>flexi</span>pay</Link><p>Smarter ways to bring home the technology you love.</p></div>
      <div className="footer-links"><div><h2>Explore</h2><a href="/#catalog">All electronics</a><a href="/#how-it-works">How it works</a></div><div><h2>Support</h2><a href="/#support">Contact us</a><a href="/#support">Help centre</a></div><div><h2>Legal</h2><a href="#terms">Terms of use</a><a href="#privacy">Privacy policy</a></div></div>
    </div>
    <div className="footer-bottom"><span>© 2026 FlexiPay. Demo storefront.</span><span>EMI plans backed by mutual funds</span></div>
  </footer>;
}

function Catalog() {
  const [products, setProducts] = useState<ProductSummary[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [error, setError] = useState('');
  useEffect(() => { Promise.all([fetch(apiUrl('/api/products')), fetch(apiUrl('/api/categories'))]).then(async ([productsResponse, categoriesResponse]) => { if (!productsResponse.ok || !categoriesResponse.ok) throw new Error(); return [await productsResponse.json(), await categoriesResponse.json()]; }).then(([productData, categoryData]) => { setProducts(productData); setCategories(categoryData); }).catch(() => setError('Catalog data is currently unavailable.')); }, []);
  if (error) return <main className="status">{error}</main>;
  const featured = products[0];
  const picks = products.slice(1, 4);
  const trending = products.slice(3);
  if (!featured) return <main className="status">Loading electronics…</main>;
  return <main className="retail-home" id="catalog">
    <section className="retail-hero"><div className="retail-hero-copy"><span>FLEXIPAY STORE</span><h1>Find your next<br />device, your way.</h1><p>Flexible EMI plans for the technology you want now.</p><Link to={`/products/${featured.slug}`}>Shop featured device <b>→</b></Link></div><Link className="retail-hero-product" to={`/products/${featured.slug}`}><img src={featured.imageUrl} alt={featured.name} /><div><small>Featured device</small><strong>{featured.name}</strong><span>From {rupees(featured.pricePaise)}</span></div></Link></section>
    <section className="retail-section"><header><h2>Best picks for you</h2><Link to="#trending">View all</Link></header><div className="retail-picks">{picks.map(product => <Link to={`/products/${product.slug}`} key={product.id}><img src={product.imageUrl} alt={product.name} style={{ transform: `scale(${product.imageScale})` }} /><div><small>{product.defaultStorage}</small><h3>{product.name}</h3><strong>{rupees(product.pricePaise)}</strong></div></Link>)}</div></section>
    <section className="retail-section"><header><h2>Shop by category</h2></header><div className="retail-categories">{categories.map(category => <Link to={`/categories/${category.slug}`} key={category.id}><img src={category.imageUrl} alt="" style={{ transform: `scale(${category.imageScale})` }} /><div><h3>{category.name}</h3><p>{category.description}</p></div></Link>)}</div></section>
    <section className="retail-section" id="plans"><header><h2>Top trending</h2><a href="#plans">View all</a></header><div className="retail-trending">{trending.map(product => <Link to={`/products/${product.slug}`} key={product.id}><div className="trending-image-frame"><img src={product.imageUrl} alt={product.name} style={{ transform: `scale(${product.imageScale})` }} /></div><h3>{product.name}</h3><small>{product.defaultStorage}</small><strong>{rupees(product.pricePaise)}</strong></Link>)}</div></section>
    <section className="how-it-works" id="how-it-works" aria-labelledby="how-it-works-title"><div><span className="eyebrow">HOW FLEXIPAY WORKS</span><h2 id="how-it-works-title">Bring home what you need, on a plan that fits.</h2></div><div className="steps"><p><b>01</b>Choose an electronic and the configuration that suits you.</p><p><b>02</b>Compare monthly plans and select the tenure you prefer.</p><p><b>03</b>Share your details and we’ll take it from there.</p></div></section>
    <section className="home-support" id="support" aria-labelledby="support-title"><div><span>FLEXIPAY SUPPORT</span><h2 id="support-title">Questions before you choose a plan?</h2><p>Our support team can help with plan selection, product options and your application.</p></div><div className="support-actions"><a href="mailto:support@flexipay.example">Contact support <b>→</b></a><a href="/#how-it-works">See how plans work <b>→</b></a></div></section>
  </main>;
}

function CategoryPage() {
  const { slug } = useParams();
  const [category, setCategory] = useState<Category | null>(null);
  const [products, setProducts] = useState<ProductSummary[]>([]);
  const [error, setError] = useState('');
  useEffect(() => {
    setCategory(null); setProducts([]); setError('');
    fetch(apiUrl(`/api/categories/${slug}/products`)).then(async response => {
      if (response.status === 404) throw new Error('This category could not be found.');
      if (!response.ok) throw new Error('Category products are currently unavailable.');
      return response.json();
    }).then(data => { setCategory(data.category); setProducts(data.products); }).catch((e: Error) => setError(e.message));
  }, [slug]);
  if (error) return <main className="status"><p>{error}</p><Link to="/">Back to store</Link></main>;
  if (!category) return <main className="status">Loading category…</main>;
  return <main className="collection-page">
    <header className="collection-heading"><Link to="/">← All categories</Link><p>{category.description}</p><h1>{category.name}</h1></header>
    {products.length ? <div className="collection-grid">{products.map(product => <Link className="collection-card" to={`/products/${product.slug}`} key={product.id}><img src={product.imageUrl} alt={product.name} style={{ transform: `scale(${product.imageScale})` }} /><div><small>{product.defaultStorage}</small><h2>{product.name}</h2><p>{product.short_description}</p><strong>From {rupees(product.pricePaise)}</strong><span>Explore options →</span></div></Link>)}</div> : <p className="collection-empty">Products in this category are coming soon.</p>}
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
    fetch(apiUrl(`/api/products/${slug}`)).then(async response => {
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
  return <main className="product-page mx-auto w-full">
    <div className="breadcrumb"><Link to="/">← All electronics</Link><span>Choose your plan</span></div>
    <div className="detail-grid">
      <section className="product-card">
        <div className="product-copy"><span className="new">NEW</span><h1>{product.name}</h1><p>{variant.configurationLabel} · {variant.label}</p></div>
        <div className="product-image-frame">
          <img className="product-image" src={variant.imageUrl || product.imageUrl} alt={`${product.name} in ${variant.label}`} />
        </div>
        <section className="specifications" aria-label={`${product.name} specifications`}><p>Key specifications</p><dl>{product.specifications.map(specification => <div key={specification.id}><dt>{specification.label}</dt><dd>{specification.value}</dd></div>)}</dl></section>
        <div className="variant-pickers">
          <div className="storage-picker"><p>Configuration</p><div role="radiogroup" aria-label="Choose configuration">{configurationOptions.map(configuration => <button type="button" key={`${configuration.ram}-${configuration.storage}`} className={configuration.ram === variant.ram && configuration.storage === variant.storage ? 'storage-option active' : 'storage-option'} onClick={() => selectConfiguration(configuration)} role="radio" aria-checked={configuration.ram === variant.ram && configuration.storage === variant.storage}>{configuration.configurationLabel}</button>)}</div></div>
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
    fetch(apiUrl(`/api/products/${productSlug}`)).then(response => response.ok ? response.json() : Promise.reject()).then((data: Product) => setProduct(data)).catch(() => setError('Checkout details are currently unavailable.'));
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
  return <main className="commerce-page"><div className="commerce-heading"><span className="eyebrow">SECURE CHECKOUT</span><h1>Almost there.</h1><p>Share your details to continue with your selected plan.</p></div><div className="checkout-layout"><form className="checkout-form" noValidate onSubmit={submit}><h2>Contact details</h2><label>Full name<input aria-invalid={Boolean(fieldErrors.name)} aria-describedby={fieldErrors.name ? 'name-error' : undefined} name="name" autoComplete="name" placeholder="Your full name" onChange={() => clearFieldError('name')} />{fieldErrors.name && <small id="name-error" className="field-error">{fieldErrors.name}</small>}</label><label>Email address<input aria-invalid={Boolean(fieldErrors.email)} aria-describedby={fieldErrors.email ? 'email-error' : undefined} type="email" name="email" autoComplete="email" placeholder="you@example.com" onChange={() => clearFieldError('email')} />{fieldErrors.email && <small id="email-error" className="field-error">{fieldErrors.email}</small>}</label><label>Mobile number<input aria-invalid={Boolean(fieldErrors.phone)} aria-describedby={fieldErrors.phone ? 'phone-error' : undefined} type="tel" name="phone" inputMode="numeric" autoComplete="tel" placeholder="10-digit mobile number" onChange={() => clearFieldError('phone')} />{fieldErrors.phone && <small id="phone-error" className="field-error">{fieldErrors.phone}</small>}</label><label>Delivery city<input aria-invalid={Boolean(fieldErrors.city)} aria-describedby={fieldErrors.city ? 'city-error' : undefined} name="city" autoComplete="address-level2" placeholder="City" onChange={() => clearFieldError('city')} />{fieldErrors.city && <small id="city-error" className="field-error">{fieldErrors.city}</small>}</label><button className="proceed-button" type="submit">Place order <span>→</span></button><p className="summary-note">By continuing, you agree to be contacted about your EMI application.</p></form><aside className="order-summary checkout-summary"><p className="eyebrow">YOUR SELECTED PLAN</p><div className="summary-product"><span>{product.name}</span><strong>{rupees(plan.monthlyPaymentPaise)}/mo</strong><small>{variant.configurationLabel} · {variant.label} · {plan.tenureMonths} months</small></div><div><span>Interest rate</span><strong>{rate(plan.interestRateBps)}</strong></div>{plan.cashbackPaise > 0 && <div className="summary-cashback"><span>Potential cashback</span><strong>{rupees(plan.cashbackPaise)}</strong></div>}<div><span>Monthly commitment</span><strong>{rupees(plan.monthlyPaymentPaise)}</strong></div></aside></div></main>;
}

export default function App() { return <div className="site-shell"><ScrollManager /><style>{`.plan-card.selected { box-shadow: 0 5px 16px #008a6026; } .catalog-intro { margin-inline: auto; text-align: center; } .checkout-form .proceed-button { justify-content: center; position: relative; } .checkout-form .proceed-button span { position: absolute; right: 18px; } .home-benefits { margin-top: 76px; padding: 6px 0 2px; } .home-benefits h2, .home-closing h2 { max-width: 560px; margin: 9px 0 0; font-size: clamp(28px, 4vw, 43px); font-weight: 600; letter-spacing: -.05em; line-height: 1.1; } .benefit-list { display: grid; grid-template-columns: repeat(3, 1fr); gap: 17px; margin-top: 31px; } .benefit-list article { min-height: 192px; padding: 23px; border: 1px solid #dfe8e5; border-radius: 18px; background: #fff; } .benefit-list span { color: #078260; font-size: 12px; font-weight: 700; } .benefit-list h3 { margin: 21px 0 7px; font-size: 18px; letter-spacing: -.03em; } .benefit-list p { margin: 0; color: #68767d; font-size: 13px; line-height: 1.55; } .home-closing { display: flex; align-items: end; justify-content: space-between; gap: 35px; margin-top: 76px; padding: 42px; border-radius: 22px; background: #e0f5eb; } .home-closing .eyebrow { color: #087b5a; } .home-closing p { max-width: 530px; margin: 13px 0 0; color: #51656a; line-height: 1.55; } .closing-link { display: flex; align-items: center; gap: 24px; flex: none; padding: 13px 16px; border-radius: 10px; background: #0d2829; color: #fff; font-size: 14px; font-weight: 700; } @media (max-width: 740px) { .benefit-list { grid-template-columns: 1fr; } .home-closing { display: grid; padding: 28px 24px; margin-top: 48px; } .home-benefits { margin-top: 48px; } }`}</style><SiteHeader /><Routes><Route path="/" element={<Catalog />} /><Route path="/categories/:slug" element={<CategoryPage />} /><Route path="/products/:slug" element={<ProductPage />} /><Route path="/checkout" element={<CheckoutPage />} /><Route path="*" element={<Navigate to="/" replace />} /></Routes><SiteFooter /></div>; }
