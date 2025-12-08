import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';
import type { APIContext } from 'astro';

export async function GET(context: APIContext) {
	const posts = await getCollection('blog');

	return rss({
		title: 'ex10x Blog',
		description: 'Practical guides and insights on using AI to boost your productivity.',
		site: context.site || 'https://ex10x.com',
		items: posts
			.sort((a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf())
			.map((post) => ({
				title: post.data.title,
				pubDate: post.data.pubDate,
				description: post.data.description,
				link: `/blog/${post.slug}/`,
				categories: post.data.tags,
				author: post.data.author,
			})),
		customData: `<language>en-us</language>`,
	});
}
