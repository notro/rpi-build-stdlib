static int bcm2708_pinctrl_gpiochip_find(struct gpio_chip *gc, void *data)
{
	pr_debug("%s: base = %d\n", __func__, gc->base);
	return gc->base == 0 ? 1 : 0;
}

static int bcm2708_pinctrl_probe(struct platform_device *pdev)
{
	struct device *dev = &pdev->dev;
	struct device_node *np = dev->of_node;
	struct bcm2708_pinctrl *pc;
	struct gpio_chip *gc;
	struct resource iomem;
	int err;
	BUILD_BUG_ON(ARRAY_SIZE(bcm2708_gpio_pins) != BCM2708_NUM_GPIOS);
	BUILD_BUG_ON(ARRAY_SIZE(bcm2708_gpio_groups) != BCM2708_NUM_GPIOS);

	gc = gpiochip_find(NULL, bcm2708_pinctrl_gpiochip_find);
	if (!gc)
		return -EPROBE_DEFER;

	gc->of_node = np;
	gc->of_gpio_n_cells = 2;
	gc->of_xlate = of_gpio_simple_xlate;

	pc = devm_kzalloc(dev, sizeof(*pc), GFP_KERNEL);
	if (!pc)
		return -ENOMEM;

	platform_set_drvdata(pdev, pc);
	pc->dev = dev;

	err = of_address_to_resource(np, 0, &iomem);
	if (err) {
		dev_err(dev, "could not get IO memory\n");
		return err;
	}

	pc->base = devm_ioremap_resource(dev, &iomem);
	if (IS_ERR(pc->base))
		return PTR_ERR(pc->base);

	pc->gpio_chip = *gc;

	pc->pctl_dev = pinctrl_register(&bcm2708_pinctrl_desc, dev, pc);
	if (!pc->pctl_dev)
		return -EINVAL;

	pc->gpio_range = bcm2708_pinctrl_gpio_range;
	pc->gpio_range.base = pc->gpio_chip.base;
	pc->gpio_range.gc = &pc->gpio_chip;
	pinctrl_add_gpio_range(pc->pctl_dev, &pc->gpio_range);

	return 0;
}

