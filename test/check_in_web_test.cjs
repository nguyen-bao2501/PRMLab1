const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
(async () => {
  const root = path.resolve(__dirname, '../src/main/resources/static');
  const server = http.createServer((req, res) => {
    const name = new URL(req.url, 'http://localhost').pathname.slice(1);
    if (!['check-in.html', 'check-in.css', 'check-in.js'].includes(name)) {
      res.writeHead(404); return res.end();
    }
    res.setHeader('Content-Type', {'.html':'text/html; charset=utf-8', '.css':'text/css', '.js':'text/javascript'}[path.extname(name)]);
    res.end(fs.readFileSync(path.join(root, name)));
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const baseUrl = `http://127.0.0.1:${server.address().port}`;
  const browser = await chromium.launch({channel:'msedge',headless:true});
  const page = await browser.newPage();
  let failConfirm = false;
  await page.route('**/v1/public/attendance/**', async route => {
    const path = new URL(route.request().url()).pathname;
    if (path.endsWith('check-in') && failConfirm) {
      failConfirm = false;
      return route.fulfill({status:400,json:{success:false,message:'Mã QR đã hết hạn. Hãy quét mã mới.'}});
    }
    const data = path.endsWith('config') ? {clientId:'test-only-client'} : path.endsWith('identity') ?
      {fullName:'Nguyễn Minh Anh',studentCode:'SE191200',email:'student@example.test'} :
      {studentName:'Nguyễn Minh Anh',email:'student@example.test',sessionId:8};
    await route.fulfill({json:{success:true,data}});
  });
  await page.route('https://accounts.google.com/gsi/client', route => route.fulfill({contentType:'text/javascript',body:`
    window.google={accounts:{id:{initialize(o){this.callback=o.callback},disableAutoSelect(){},renderButton(el,options){
      const b=document.createElement('button');b.textContent='Đăng nhập với Google';b.style.cssText='padding:14px 28px;background:white;border:1px solid #dce1d4;border-radius:8px;color:#173d35';
      b.style.width=options.width+'px';b.onclick=()=>this.callback({credential:'test-token'});el.appendChild(b);
    }}}};` }));
  fs.mkdirSync('build/previews',{recursive:true});
  for (const width of [1440,390,320]) {
    await page.setViewportSize({width,height:1000});
    await page.goto(`${baseUrl}/check-in.html`);
    await page.locator('#message.error').waitFor();
    assert.match(await page.locator('#message').innerText(),/không hợp lệ/);
    await page.screenshot({path:`build/previews/check-in-error-${width}.png`,fullPage:true});
    await page.goto(`${baseUrl}/check-in.html#token=0123456789abcdef0123456789abcdef`);
    await page.reload();
    await page.getByRole('button',{name:'Đăng nhập với Google',exact:true}).waitFor();
    await page.screenshot({path:`build/previews/check-in-login-${width}.png`,fullPage:true});
    await page.getByRole('button',{name:'Đăng nhập với Google',exact:true}).click();
    await page.locator('#identity:not([hidden])').waitFor();
    assert.equal(await page.locator('#step-review').getAttribute('aria-current'),'step');
    await page.screenshot({path:`build/previews/check-in-review-${width}.png`,fullPage:true});
    if(width===1440){
      await page.locator('#switch').click();
      assert.equal(await page.locator('#full-name').inputValue(),'');
      await page.getByRole('button',{name:'Đăng nhập với Google',exact:true}).click();
      await page.locator('#identity:not([hidden])').waitFor();
      failConfirm=true;
      await page.locator('#confirm').click();
      await page.locator('#message.error').waitFor();
      assert.equal(await page.locator('#confirm').isEnabled(),true);
    }
    await page.locator('#confirm').click();
    await page.locator('#message.success').waitFor();
    assert.equal(await page.locator('#step-done').getAttribute('aria-current'),'step');
    assert.equal(new URL(page.url()).hash,'');
    assert.equal(await page.locator('#confirm').isVisible(),false);
    await page.screenshot({path:`build/previews/check-in-success-${width}.png`,fullPage:true});
    const fits = await page.evaluate(()=>document.documentElement.scrollWidth <= innerWidth);
    assert.equal(fits,true,`Horizontal overflow at ${width}`);
    console.log(`PASS ${width}px: invalid QR, login, identity, success, responsive layout`);
  }
  await browser.close();
  await new Promise(resolve => server.close(resolve));
})().catch(e=>{console.error(e);process.exit(1)});
